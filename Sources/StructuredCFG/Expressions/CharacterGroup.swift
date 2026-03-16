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
      throw CharacterGroupParseError("Character groups must be fully bracketed or unbracketed")
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
      throw CharacterGroupParseError("Character groups must start with '['")
    }

    var isNegated = false
    var content = String(string.dropFirst())

    if content.hasPrefix("^") {
      isNegated = true
      content = String(content.dropFirst())
    }

    guard content.hasSuffix("]") else {
      throw CharacterGroupParseError("Character groups must end with ']'")
    }
    content = String(content.dropLast())

    var members: [Member] = []
    let characters = Array(content)
    var i = 0

    while i < characters.count {
      let character = characters[i]
      if character == "\\" {
        guard i + 1 < characters.count else {
          throw CharacterGroupParseError("Character groups cannot end with an escape")
        }

        let escapedCharacter = characters[i + 1]
        switch escapedCharacter {
        case "d":
          members.append(contentsOf: Self.digitMembers)
        case "w":
          members.append(contentsOf: Self.wordMembers)
        case "s":
          members.append(contentsOf: Self.whitespaceMembers)
        case "D":
          guard !isNegated, members.isEmpty, i + 2 == characters.count else {
            throw CharacterGroupParseError(
              "Negated predefined classes are only supported as standalone groups"
            )
          }
          isNegated = true
          members.append(contentsOf: Self.digitMembers)
        case "W":
          guard !isNegated, members.isEmpty, i + 2 == characters.count else {
            throw CharacterGroupParseError(
              "Negated predefined classes are only supported as standalone groups"
            )
          }
          isNegated = true
          members.append(contentsOf: Self.wordMembers)
        case "S":
          guard !isNegated, members.isEmpty, i + 2 == characters.count else {
            throw CharacterGroupParseError(
              "Negated predefined classes are only supported as standalone groups"
            )
          }
          isNegated = true
          members.append(contentsOf: Self.whitespaceMembers)
        case "i", "I", "c", "C":
          throw CharacterGroupParseError("XML name classes are not supported")
        case "n":
          members.append(.escaped(.newline))
        case "r":
          members.append(.escaped(.carriageReturn))
        case "t":
          members.append(.escaped(.tab))
        default:
          if let escape = EscapeSequence(escapedCharacter: escapedCharacter) {
            members.append(.escaped(escape))
          } else {
            members.append(.character(escapedCharacter))
          }
        }
        i += 2
      } else if i + 2 < characters.count && characters[i + 1] == "-" {
        let startCharacter = characters[i]
        let endCharacter = characters[i + 2]
        if startCharacter != "-" && endCharacter != "-" {
          members.append(.range(startCharacter, endCharacter))
          i += 3
        } else {
          members.append(.character(character))
          i += 1
        }
      } else {
        members.append(.character(character))
        i += 1
      }
    }

    return (isNegated, members)
  }

  public enum Member: Hashable, Sendable {
    case character(Character)
    case range(Character, Character)
    case escaped(EscapeSequence)
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

// MARK: - CharacterGroupParseError

public struct CharacterGroupParseError: Error, Hashable, Sendable {
  public let message: String

  public init(_ message: String) {
    self.message = message
  }
}
