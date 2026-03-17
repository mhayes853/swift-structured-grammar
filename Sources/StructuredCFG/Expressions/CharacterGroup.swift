// MARK: - CharacterGroup

public struct CharacterGroup: Hashable, Sendable, ExpressionComponent {
  public let isNegated: Bool
  public let members: [Member]

  public init(isNegated: Bool, members: [Member]) {
    self.isNegated = isNegated
    self.members = members
  }

  @_disfavoredOverload
  public init(_ string: String) throws {
    let processedString: String
    switch (string.hasPrefix("["), string.hasSuffix("]")) {
    case (false, false):
      processedString = "[" + string + "]"
    case (true, true):
      processedString = string
    default:
      throw CharacterGroup.ParseError("Character groups must be fully bracketed or unbracketed")
    }

    let parsed = try Self.parse(processedString)
    self.isNegated = parsed.isNegated
    self.members = parsed.members
  }

  public init(_ string: StaticString) {
    do {
      try self.init(String(describing: string))
    } catch {
      fatalError("Unable to parse CharacterGroup from '\(string)': \(error)")
    }
  }

  public init(_ range: ClosedRange<Character>) {
    self.init(isNegated: false, members: [.range(range.lowerBound, range.upperBound)])
  }

  public var expression: Expression {
    Expression.characterGroup(self)
  }

  public func negated() -> CharacterGroup {
    CharacterGroup(isNegated: !self.isNegated, members: self.members)
  }

  public static var digit: Self {
    Self(isNegated: false, members: Self.digitMembers)
  }

  public static var word: Self {
    Self(isNegated: false, members: Self.wordMembers)
  }

  public static var whitespace: Self {
    Self(isNegated: false, members: Self.whitespaceMembers)
  }

  public var isDigit: Bool {
    self.matches(isNegated: false, members: Self.digitMembers)
  }

  public var isWord: Bool {
    self.matches(isNegated: false, members: Self.wordMembers)
  }

  public var isWhitespace: Bool {
    self.matches(isNegated: false, members: Self.whitespaceMembers)
  }

  public var isNonDigit: Bool {
    self.matches(isNegated: true, members: Self.digitMembers)
  }

  public var isNonWord: Bool {
    self.matches(isNegated: true, members: Self.wordMembers)
  }

  public var isNonWhitespace: Bool {
    self.matches(isNegated: true, members: Self.whitespaceMembers)
  }

  private static func parse(_ string: String) throws -> (isNegated: Bool, members: [Member]) {
    guard string.hasPrefix("[") else {
      throw CharacterGroup.ParseError("Character groups must start with '['")
    }

    var isNegated = false
    var content = String(string.dropFirst())

    if content.hasPrefix("^") {
      isNegated = true
      content = String(content.dropFirst())
    }

    guard content.hasSuffix("]") else {
      throw CharacterGroup.ParseError("Character groups must end with ']'")
    }
    content = String(content.dropLast())

    if !isNegated {
      switch content {
      case #"\D"#:
        return (true, Self.digitMembers)
      case #"\W"#:
        return (true, Self.wordMembers)
      case #"\S"#:
        return (true, Self.whitespaceMembers)
      default:
        break
      }
    }

    var members: [Member] = []
    let characters = Array(content)
    var i = 0

    while i < characters.count {
      let character = characters[i]
      if character == "\\" {
        let (newMembers, newIndex) = try parseEscapeSequence(
          characters: characters,
          index: i,
          isNegated: isNegated,
          existingMembers: members
        )
        members.append(contentsOf: newMembers)
        i = newIndex
      } else if character == "#" && i + 1 < characters.count && characters[i + 1] == "x" {
        let (newMembers, newIndex) = try parseHexMember(characters: characters, index: i)
        members.append(contentsOf: newMembers)
        i = newIndex
      } else if i + 2 < characters.count && characters[i + 1] == "-" {
        let (newMembers, newIndex) = try parseCharacterRange(characters: characters, index: i)
        members.append(contentsOf: newMembers)
        i = newIndex
      } else {
        members.append(.character(character))
        i += 1
      }
    }

    return (isNegated, members)
  }

  private static func parseEscapeSequence(
    characters: [Character],
    index: Int,
    isNegated: Bool,
    existingMembers: [Member]
  ) throws -> (members: [Member], index: Int) {
    var members = [Member]()

    guard index + 1 < characters.count else {
      throw CharacterGroup.ParseError("Character groups cannot end with an escape")
    }

    let escapedCharacter = characters[index + 1]
    switch escapedCharacter {
    case "d":
      members.append(contentsOf: Self.digitMembers)
    case "w":
      members.append(contentsOf: Self.wordMembers)
    case "s":
      members.append(contentsOf: Self.whitespaceMembers)
    case "D":
      guard !isNegated, existingMembers.isEmpty, index + 2 == characters.count else {
        throw CharacterGroup.ParseError(
          "Negated predefined classes are only supported as standalone groups"
        )
      }
      members.append(contentsOf: Self.digitMembers)
    case "W":
      guard !isNegated, existingMembers.isEmpty, index + 2 == characters.count else {
        throw CharacterGroup.ParseError(
          "Negated predefined classes are only supported as standalone groups"
        )
      }
      members.append(contentsOf: Self.wordMembers)
    case "S":
      guard !isNegated, existingMembers.isEmpty, index + 2 == characters.count else {
        throw CharacterGroup.ParseError(
          "Negated predefined classes are only supported as standalone groups"
        )
      }
      members.append(contentsOf: Self.whitespaceMembers)
    case "i", "I", "c", "C":
      throw CharacterGroup.ParseError("XML name classes are not supported")
    case "n":
      members.append(.escaped(.newline))
    case "r":
      members.append(.escaped(.carriageReturn))
    case "t":
      members.append(.escaped(.tab))
    case "x":
      return try parseHexEscape(characters: characters, index: index)
    default:
      if let escape = EscapeSequence(escapedCharacter: escapedCharacter) {
        members.append(.escaped(escape))
      } else {
        members.append(.character(escapedCharacter))
      }
    }
    return (members, index + 2)
  }

  private static func parseHexEscape(characters: [Character], index: Int) throws -> (members: [Member], index: Int) {
    guard index + 2 < characters.count else {
      throw CharacterGroup.ParseError("Incomplete hex escape")
    }
    let hexStart = index + 2
    var hexEnd = hexStart
    while hexEnd < characters.count && characters[hexEnd].isHexDigit {
      hexEnd += 1
    }
    guard hexEnd > hexStart else {
      throw CharacterGroup.ParseError("Invalid hex escape")
    }
    let hexString = String(characters[hexStart..<hexEnd])
    guard let codePoint = Self.parseHex(hexString) else {
      throw CharacterGroup.ParseError("Invalid hex value: \(hexString)")
    }
    return ([.hex(codePoint)], hexEnd)
  }

  private static func parseHexMember(characters: [Character], index: Int) throws -> (members: [Member], index: Int) {
    let hexStart = index + 2
    var hexEnd = hexStart
    while hexEnd < characters.count && characters[hexEnd].isHexDigit {
      hexEnd += 1
    }
    guard hexEnd > hexStart else {
      throw CharacterGroup.ParseError("Invalid hex character")
    }

    if hexEnd + 1 < characters.count && characters[hexEnd] == "-" && 
       characters[hexEnd + 1] == "#" && hexEnd + 2 < characters.count && 
       characters[hexEnd + 2] == "x" {
      let rangeStartHex = String(characters[hexStart..<hexEnd])
      guard let rangeStart = Self.parseHex(rangeStartHex) else {
        throw CharacterGroup.ParseError("Invalid hex value: \(rangeStartHex)")
      }

      let rangeHexStart = hexEnd + 3
      var rangeHexEnd = rangeHexStart
      while rangeHexEnd < characters.count && characters[rangeHexEnd].isHexDigit {
        rangeHexEnd += 1
      }
      guard rangeHexEnd > rangeHexStart else {
        throw CharacterGroup.ParseError("Invalid hex character")
      }

      let rangeEndHex = String(characters[rangeHexStart..<rangeHexEnd])
      guard let rangeEnd = Self.parseHex(rangeEndHex) else {
        throw CharacterGroup.ParseError("Invalid hex value: \(rangeEndHex)")
      }

      guard rangeStart <= rangeEnd else {
        throw CharacterGroup.ParseError("Invalid hex range: start > end")
      }

      return ([.hexRange(rangeStart, rangeEnd)], rangeHexEnd)
    } else {
      let hexString = String(characters[hexStart..<hexEnd])
      guard let codePoint = Self.parseHex(hexString) else {
        throw CharacterGroup.ParseError("Invalid hex value: \(hexString)")
      }
      return ([.hex(codePoint)], hexEnd)
    }
  }

  private static func parseCharacterRange(characters: [Character], index: Int) throws -> (members: [Member], index: Int) {
    let startCharacter = characters[index]
    let endCharacter = characters[index + 2]
    if startCharacter != "-" && endCharacter != "-" {
      return ([.range(startCharacter, endCharacter)], index + 3)
    } else {
      return ([.character(characters[index])], index + 1)
    }
  }

  private static func parseHex(_ string: String) -> UInt32? {
    guard !string.isEmpty else { return nil }
    return UInt32(string, radix: 16)
  }

  public enum Member: Hashable, Sendable {
    case character(Character)
    case range(Character, Character)
    case escaped(EscapeSequence)
    case hex(UInt32)
    case hexRange(UInt32, UInt32)
  }

  public enum EscapeSequence: Hashable, Sendable {
    case backslash
    case pipe
    case period
    case hyphen
    case caret
    case question
    case asterisk
    case plus
    case leftBrace
    case rightBrace
    case leftParen
    case rightParen
    case leftBracket
    case rightBracket
    case newline
    case carriageReturn
    case tab
  }

  private static let digitMembers: [Member] = [.range("0", "9")]

  private static let wordMembers: [Member] = [
    .range("a", "z"),
    .range("A", "Z"),
    .range("0", "9"),
    .character("_")
  ]

  private static let whitespaceMembers: [Member] = [
    .character(" "),
    .escaped(.tab),
    .escaped(.newline),
    .escaped(.carriageReturn)
  ]

  private func matches(isNegated: Bool, members: [Member]) -> Bool {
    self.isNegated == isNegated && Self.memberCounts(self.members) == Self.memberCounts(members)
  }

  private static func memberCounts(_ members: [Member]) -> [Member: Int] {
    members.reduce(into: [Member: Int]()) { counts, member in
      counts[member, default: 0] += 1
    }
  }
}

extension CharacterGroup.EscapeSequence {
  fileprivate init?(escapedCharacter: Character) {
    switch escapedCharacter {
    case "\\":
      self = .backslash
    case "|":
      self = .pipe
    case ".":
      self = .period
    case "-":
      self = .hyphen
    case "^":
      self = .caret
    case "?":
      self = .question
    case "*":
      self = .asterisk
    case "+":
      self = .plus
    case "{":
      self = .leftBrace
    case "}":
      self = .rightBrace
    case "(":
      self = .leftParen
    case ")":
      self = .rightParen
    case "[":
      self = .leftBracket
    case "]":
      self = .rightBracket
    default:
      return nil
    }
  }
}

// MARK: - CharacterGroup.ParseError

extension CharacterGroup {
  public struct ParseError: Error, Hashable, Sendable {
    public let message: String

    public init(_ message: String) {
      self.message = message
    }
  }
}
