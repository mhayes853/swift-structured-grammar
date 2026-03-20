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
      throw ParseError.mustBeFullyBracketedOrUnbracketed
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

  public static var all: Self {
    Self(
      isNegated: false,
      members: [.unicodeScalarRange(Unicode.Scalar(UInt32(0))!, Unicode.Scalar(UInt32(0x10FFFF))!)]
    )
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
      throw ParseError.mustStartWithOpeningBracket
    }

    var isNegated = false
    var content = String(string.dropFirst())

    if content.hasPrefix("^") {
      isNegated = true
      content = String(content.dropFirst())
    }

    guard content.hasSuffix("]") else {
      throw ParseError.mustEndWithClosingBracket
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
      throw ParseError.cannotEndWithEscape
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
        throw ParseError.negatedPredefinedClassesMustBeStandalone
      }
      members.append(contentsOf: Self.digitMembers)
    case "W":
      guard !isNegated, existingMembers.isEmpty, index + 2 == characters.count else {
        throw ParseError.negatedPredefinedClassesMustBeStandalone
      }
      members.append(contentsOf: Self.wordMembers)
    case "S":
      guard !isNegated, existingMembers.isEmpty, index + 2 == characters.count else {
        throw ParseError.negatedPredefinedClassesMustBeStandalone
      }
      members.append(contentsOf: Self.whitespaceMembers)
    case "i", "I", "c", "C":
      throw ParseError.xmlNameClassesAreNotSupported
    case "n":
      members.append(.escaped(.newline))
    case "r":
      members.append(.escaped(.carriageReturn))
    case "t":
      members.append(.escaped(.tab))
    case "x":
      return try parseHexEscape(characters: characters, index: index)
    case "u", "U":
      return try parseUnicodeEscape(characters: characters, index: index)
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
      throw ParseError.incompleteHexEscape
    }
    let hexStart = index + 2
    var hexEnd = hexStart
    while hexEnd < characters.count && characters[hexEnd].isHexDigit {
      hexEnd += 1
    }
    guard hexEnd > hexStart else {
      throw ParseError.invalidHexEscape
    }
    let hexString = String(characters[hexStart..<hexEnd])
    guard let scalar = Self.parseHex(hexString) else {
      throw ParseError.invalidHexValue(hexString)
    }
    return ([.hex(scalar)], hexEnd)
  }

  private static func parseUnicodeEscape(characters: [Character], index: Int) throws -> (members: [Member], index: Int) {
    let escapedCharacter = characters[index + 1]
    let expectedDigits = escapedCharacter == "u" ? 4 : 8

    guard index + 1 + expectedDigits < characters.count else {
      throw ParseError.incompleteHexEscape
    }

    let hexStart = index + 2
    let hexEnd = hexStart + expectedDigits
    let hexString = String(characters[hexStart..<hexEnd])

    guard hexString.allSatisfy({ $0.isHexDigit }) else {
      throw ParseError.invalidHexEscape
    }

    guard let startScalar = Self.parseHex(hexString) else {
      throw ParseError.invalidHexValue(hexString)
    }

    if hexEnd + 1 < characters.count && characters[hexEnd] == "-" {
      let secondBackslashPos = hexEnd + 1
      if secondBackslashPos < characters.count && characters[secondBackslashPos] == "\\" {
        let secondEscapePos = secondBackslashPos + 1
        if secondEscapePos < characters.count {
          let secondChar = characters[secondEscapePos]
          let secondExpectedDigits = secondChar == "u" ? 4 : (secondChar == "U" ? 8 : 0)
          if secondExpectedDigits > 0 && secondEscapePos + 1 + secondExpectedDigits <= characters.count {
            let secondHexEnd = secondEscapePos + 1 + secondExpectedDigits
            let secondHexString = String(characters[secondEscapePos + 1..<secondHexEnd])
            guard secondHexString.allSatisfy({ $0.isHexDigit }) else {
              throw ParseError.invalidHexEscape
            }
            guard let endScalar = Self.parseHex(secondHexString) else {
              throw ParseError.invalidHexValue(secondHexString)
            }
            guard startScalar.value <= endScalar.value else {
              throw ParseError.invalidHexRangeStartGreaterThanEnd
            }
            return ([.unicodeScalarRange(startScalar, endScalar)], secondHexEnd)
          }
        }
      }
    }

    return ([.unicodeScalarRange(startScalar, startScalar)], hexEnd)
  }

  private static func parseHexMember(characters: [Character], index: Int) throws -> (members: [Member], index: Int) {
    let hexStart = index + 2
    var hexEnd = hexStart
    while hexEnd < characters.count && characters[hexEnd].isHexDigit {
      hexEnd += 1
    }
    guard hexEnd > hexStart else {
      throw ParseError.invalidHexCharacter
    }

    if hexEnd + 1 < characters.count && characters[hexEnd] == "-" && 
       characters[hexEnd + 1] == "#" && hexEnd + 2 < characters.count && 
       characters[hexEnd + 2] == "x" {
      let rangeStartHex = String(characters[hexStart..<hexEnd])
      guard let rangeStart = Self.parseHex(rangeStartHex) else {
        throw ParseError.invalidHexValue(rangeStartHex)
      }

      let rangeHexStart = hexEnd + 3
      var rangeHexEnd = rangeHexStart
      while rangeHexEnd < characters.count && characters[rangeHexEnd].isHexDigit {
        rangeHexEnd += 1
      }
      guard rangeHexEnd > rangeHexStart else {
        throw ParseError.invalidHexCharacter
      }

      let rangeEndHex = String(characters[rangeHexStart..<rangeHexEnd])
      guard let rangeEnd = Self.parseHex(rangeEndHex) else {
        throw ParseError.invalidHexValue(rangeEndHex)
      }

      guard rangeStart.value <= rangeEnd.value else {
        throw ParseError.invalidHexRangeStartGreaterThanEnd
      }

      return ([.hexRange(rangeStart, rangeEnd)], rangeHexEnd)
    } else {
      let hexString = String(characters[hexStart..<hexEnd])
      guard let scalar = Self.parseHex(hexString) else {
        throw ParseError.invalidHexValue(hexString)
      }
      return ([.hex(scalar)], hexEnd)
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

  private static func parseHex(_ string: String) -> Unicode.Scalar? {
    guard !string.isEmpty else { return nil }
    guard let value = UInt32(string, radix: 16) else { return nil }
    return Unicode.Scalar(value)
  }

  public enum Member: Hashable, Sendable {
    case character(Character)
    case range(Character, Character)
    case escaped(EscapeSequence)
    case hex(Unicode.Scalar)
    case hexRange(Unicode.Scalar, Unicode.Scalar)
    case unicodeScalarRange(Unicode.Scalar, Unicode.Scalar)
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
    self.isNegated == isNegated && self.memberCounts == Self.memberCounts(members)
  }

  private var memberCounts: [Member: Int] {
    self.members.reduce(into: [Member: Int]()) { counts, member in
      counts[member, default: 0] += 1
    }
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
    public struct Code: RawRepresentable, Hashable, Sendable {
      public let rawValue: String

      public init(rawValue: String) {
        self.rawValue = rawValue
      }

      public static let mustBeFullyBracketedOrUnbracketed = Self(
        rawValue: "must_be_fully_bracketed_or_unbracketed"
      )

      public static let mustStartWithOpeningBracket = Self(
        rawValue: "must_start_with_opening_bracket"
      )

      public static let mustEndWithClosingBracket = Self(
        rawValue: "must_end_with_closing_bracket"
      )

      public static let cannotEndWithEscape = Self(rawValue: "cannot_end_with_escape")

      public static let negatedPredefinedClassesMustBeStandalone = Self(
        rawValue: "negated_predefined_classes_must_be_standalone"
      )

      public static let xmlNameClassesAreNotSupported = Self(
        rawValue: "xml_name_classes_are_not_supported"
      )

      public static let incompleteHexEscape = Self(rawValue: "incomplete_hex_escape")

      public static let invalidHexEscape = Self(rawValue: "invalid_hex_escape")

      public static let invalidHexCharacter = Self(rawValue: "invalid_hex_character")

      public static let invalidHexRangeStartGreaterThanEnd = Self(
        rawValue: "invalid_hex_range_start_greater_than_end"
      )

      public static let invalidHexValue = Self(rawValue: "invalid_hex_value")
    }

    public let code: Code
    public let message: String

    public init(code: Code, message: String) {
      self.code = code
      self.message = message
    }

    public static let mustBeFullyBracketedOrUnbracketed = Self(
      code: .mustBeFullyBracketedOrUnbracketed,
      message: "Character groups must be fully bracketed or unbracketed"
    )

    public static let mustStartWithOpeningBracket = Self(
      code: .mustStartWithOpeningBracket,
      message: "Character groups must start with '['"
    )

    public static let mustEndWithClosingBracket = Self(
      code: .mustEndWithClosingBracket,
      message: "Character groups must end with ']'"
    )

    public static let cannotEndWithEscape = Self(
      code: .cannotEndWithEscape,
      message: "Character groups cannot end with an escape"
    )

    public static let negatedPredefinedClassesMustBeStandalone = Self(
      code: .negatedPredefinedClassesMustBeStandalone,
      message: "Negated predefined classes are only supported as standalone groups"
    )

    public static let xmlNameClassesAreNotSupported = Self(
      code: .xmlNameClassesAreNotSupported,
      message: "XML name classes are not supported"
    )

    public static let incompleteHexEscape = Self(
      code: .incompleteHexEscape,
      message: "Incomplete hex escape"
    )

    public static let invalidHexEscape = Self(
      code: .invalidHexEscape,
      message: "Invalid hex escape"
    )

    public static let invalidHexCharacter = Self(
      code: .invalidHexCharacter,
      message: "Invalid hex character"
    )

    public static let invalidHexRangeStartGreaterThanEnd = Self(
      code: .invalidHexRangeStartGreaterThanEnd,
      message: "Invalid hex range: start > end"
    )

    public static func invalidHexValue(_ value: String) -> Self {
      Self(code: .invalidHexValue, message: "Invalid hex value: \(value)")
    }
  }
}
