import Foundation

extension Grammar {
  public struct GBNFFormatter: Formatter {
    public init() {}

    public func format(production: Production) -> String {
      guard let expression = self.simplified(expression: production.expression) else {
        return ""
      }
      return "\(production.symbol.rawValue) ::= \(self.format(expression: expression))"
    }

    private func simplified(expression: Expression) -> Expression? {
      switch expression {
      case .empty:
        return nil
      case .concat(let expressions):
        let expressions = expressions.compactMap { self.simplified(expression: $0) }
        switch expressions.count {
        case 0:
          return nil
        case 1:
          return expressions[0]
        default:
          return .concat(expressions)
        }
      case .choice(let expressions):
        let expressions = expressions.compactMap { self.simplified(expression: $0) }
        switch expressions.count {
        case 0:
          return nil
        case 1:
          return expressions[0]
        default:
          return .choice(expressions)
        }
      case .optional(let expression):
        return self.simplified(expression: expression).map(Expression.optional)
      case .zeroOrMore(let expression):
        return self.simplified(expression: expression).map(Expression.zeroOrMore)
      case .oneOrMore(let expression):
        return self.simplified(expression: expression).map(Expression.oneOrMore)
      case .group(let expression):
        return self.simplified(expression: expression).map(Expression.group)
      case .characterGroup(let characterGroup):
        return .characterGroup(characterGroup)
      case .ref(let symbol):
        return .ref(symbol)
      case .terminal(let terminal):
        return .terminal(terminal)
      }
    }

    private func format(expression: Expression) -> String {
      switch expression {
      case .empty:
        preconditionFailure("Empty expressions must be simplified before formatting.")
      case .concat(let expressions):
        expressions
          .map { expression in
            if case .choice = expression {
              "(\(self.format(expression: expression)))"
            } else {
              self.format(expression: expression)
            }
          }
          .joined(separator: " ")
      case .choice(let expressions):
        expressions.map { self.format(expression: $0) }.joined(separator: " | ")
      case .optional(let expression):
        self.formatPrimary(expression: expression) + "?"
      case .zeroOrMore(let expression):
        self.formatPrimary(expression: expression) + "*"
      case .oneOrMore(let expression):
        self.formatPrimary(expression: expression) + "+"
      case .group(let expression):
        "(\(self.format(expression: expression)))"
      case .characterGroup(let characterGroup):
        self.format(characterGroup: characterGroup)
      case .ref(let symbol):
        symbol.rawValue
      case .terminal(let terminal):
        self.format(terminal: terminal)
      }
    }

    private func formatPrimary(expression: Expression) -> String {
      if self.isPrimary(expression: expression) {
        self.format(expression: expression)
      } else {
        "(\(self.format(expression: expression)))"
      }
    }

    private func isPrimary(expression: Expression) -> Bool {
      switch expression {
      case .ref, .group, .terminal, .characterGroup:
        true
      case .empty, .concat, .choice, .optional, .zeroOrMore, .oneOrMore:
        false
      }
    }

    private func format(terminal: Terminal) -> String {
      let escaped = terminal.value.reduce(into: "") { result, character in
        switch character {
        case "\\":
          result += "\\\\"
        case "\"":
          result += "\\\""
        default:
          result.append(character)
        }
      }

      return "\"" + escaped + "\""
    }

    private func format(characterGroup: CharacterGroup) -> String {
      if let standalone = self.formatStandalone(characterGroup: characterGroup) {
        return standalone
      }

      var result = characterGroup.isNegated ? "[^" : "["

      for member in characterGroup.members {
        switch member {
        case .character(let char):
          result.append(char)
        case .range(let start, let end):
          result.append(start)
          result.append("-")
          result.append(end)
        case .category(let cat):
          result.append("\\p{\(cat)}")
        case .negatedCategory(let cat):
          result.append("\\P{\(cat)}")
        case .predefined(let predefined):
          result.append(self.format(predefined: predefined))
        case .xmlName(let xmlClass):
          switch xmlClass {
          case .nameStart:
            result.append("\\i")
          case .nonNameStart:
            result.append("\\I")
          case .nameChar:
            result.append("\\c")
          case .nonNameChar:
            result.append("\\C")
          }
        case .subtraction(let subGroup):
          result.append("-")
          result.append(self.format(characterGroup: subGroup))
        case .escaped(let escape):
          switch escape {
          case .backslash:
            result.append("\\\\")
          case .pipe:
            result.append("\\|")
          case .period:
            result.append("\\.")
          case .hyphen:
            result.append("\\-")
          case .caret:
            result.append("\\^")
          case .question:
            result.append("\\?")
          case .asterisk:
            result.append("\\*")
          case .plus:
            result.append("\\+")
          case .leftBrace:
            result.append("\\{")
          case .rightBrace:
            result.append("\\}")
          case .leftParen:
            result.append("\\(")
          case .rightParen:
            result.append("\\)")
          case .leftBracket:
            result.append("\\[")
          case .rightBracket:
            result.append("\\]")
          case .newline:
            result.append("\\n")
          case .carriageReturn:
            result.append("\\r")
          case .tab:
            result.append("\\t")
          }
        }
      }

      result.append("]")
      return result
    }

    private func formatStandalone(characterGroup: CharacterGroup) -> String? {
      guard characterGroup.members.count == 1 else { return nil }
      guard case .predefined(let predefined) = characterGroup.members[0] else { return nil }

      let characterSet = self.predefinedCharacterSet(predefined)
      let isNegated = characterGroup.isNegated != characterSet.isNegated
      return "[" + (isNegated ? "^" : "") + characterSet.members + "]"
    }

    private func format(predefined: CharacterGroup.PredefinedClass) -> String {
      let characterSet = self.predefinedCharacterSet(predefined)
      return (characterSet.isNegated ? "^" : "") + characterSet.members
    }

    private func predefinedCharacterSet(
      _ predefined: CharacterGroup.PredefinedClass
    ) -> (members: String, isNegated: Bool) {
      switch predefined {
      case .digit:
        (members: "0-9", isNegated: false)
      case .nonDigit:
        (members: "0-9", isNegated: true)
      case .word:
        (members: "a-zA-Z0-9_", isNegated: false)
      case .nonWord:
        (members: "a-zA-Z0-9_", isNegated: true)
      case .whitespace:
        (members: " \\t\\n\\r", isNegated: false)
      case .nonWhitespace:
        (members: " \\t\\n\\r", isNegated: true)
      case .wildcard:
        (members: ".", isNegated: false)
      }
    }
  }
}

extension Grammar.Formatter where Self == Grammar.GBNFFormatter {
  public static var gbnf: Grammar.GBNFFormatter {
    Grammar.GBNFFormatter()
  }
}
