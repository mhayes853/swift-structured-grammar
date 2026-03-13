public struct CharacterGroup: Hashable, Sendable, ExpressionComponent {
  public let isNegated: Bool
  public let members: [Member]

  public init(isNegated: Bool, members: [Member]) {
    self.isNegated = isNegated
    self.members = members
  }

  public init(_ string: String) {
    let parsed = Self.parse(string)
    self.isNegated = parsed.isNegated
    self.members = parsed.members
  }

  public var expression: Expression {
    Expression.characterGroup(self)
  }

  public func negated() -> CharacterGroup {
    CharacterGroup(isNegated: !self.isNegated, members: self.members)
  }

  private static func parse(_ string: String) -> (isNegated: Bool, members: [Member]) {
    guard string.hasPrefix("[") else {
      return (false, [])
    }

    var isNegated = false
    var content = String(string.dropFirst())

    if content.hasPrefix("^") {
      isNegated = true
      content = String(content.dropFirst())
    }

    guard content.hasSuffix("]") else {
      return (false, [])
    }
    content = String(content.dropLast())

    var members: [Member] = []
    var i = content.startIndex

    while i < content.endIndex {
      if content[i] == "\\" && content.index(after: i) < content.endIndex {
        let nextIndex = content.index(after: i)
        let escapedChar = content[nextIndex]

        switch escapedChar {
        case "d":
          members.append(.predefined(.digit))
        case "D":
          members.append(.predefined(.nonDigit))
        case "w":
          members.append(.predefined(.word))
        case "W":
          members.append(.predefined(.nonWord))
        case "s":
          members.append(.predefined(.whitespace))
        case "S":
          members.append(.predefined(.nonWhitespace))
        case "i":
          members.append(.xmlName(.nameStart))
        case "I":
          members.append(.xmlName(.nonNameStart))
        case "c":
          members.append(.xmlName(.nameChar))
        case "C":
          members.append(.xmlName(.nonNameChar))
        case "n":
          members.append(.escaped(.newline))
        case "r":
          members.append(.escaped(.carriageReturn))
        case "t":
          members.append(.escaped(.tab))
        default:
          members.append(.character(escapedChar))
        }
        i = content.index(after: nextIndex)
      } else if i.utf16Offset(in: content) + 2 < content.count &&
                  content.index(after: i) < content.endIndex &&
                  content[content.index(after: i)] == "-" {
        let startChar = content[i]
        let endIndex = content.index(after: content.index(after: i))
        if endIndex < content.endIndex {
          let endChar = content[endIndex]
          if startChar != "-" && endChar != "-" {
            members.append(.range(startChar, endChar))
            i = content.index(after: endIndex)
            continue
          }
        }
        members.append(.character(content[i]))
        i = content.index(after: i)
      } else {
        members.append(.character(content[i]))
        i = content.index(after: i)
      }
    }

    return (isNegated, members)
  }

  public enum Member: Hashable, Sendable {
    case character(Character)
    case range(Character, Character)
    case category(String)
    case negatedCategory(String)
    case predefined(PredefinedClass)
    case xmlName(XMLNameClass)
    case subtraction(CharacterGroup)
    case escaped(EscapeSequence)
  }

  public enum PredefinedClass: Hashable, Sendable {
    case digit
    case nonDigit
    case word
    case nonWord
    case whitespace
    case nonWhitespace
    case wildcard
  }

  public enum XMLNameClass: Hashable, Sendable {
    case nameStart
    case nonNameStart
    case nameChar
    case nonNameChar
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
}
