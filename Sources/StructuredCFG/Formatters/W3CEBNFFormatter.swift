import Foundation

extension Grammar {
  public struct W3CEBNFFormatter: Formatter {
    public init() {}

    public func format(production: Production) throws -> String {
      guard let expression = production.expression.simplified else {
        return ""
      }
      let formatted = self.format(expression: expression)
      if formatted.isEmpty {
        return ""
      }
      return "\(production.symbol.rawValue) ::= \(formatted)"
    }

    private func format(expression: Expression) -> String {
      switch expression {
      case .empty:
        preconditionFailure("Empty expressions must be simplified before formatting.")
      case .concat(let expressions):
        return expressions
          .map { expression in
            if case .choice = expression {
              "(\(self.format(expression: expression)))"
            } else {
              self.format(expression: expression)
            }
          }
          .joined(separator: " ")
      case .choice(let expressions):
        return expressions.map { self.format(expression: $0) }.joined(separator: " | ")
      case .optional(let expression):
        return self.formatPrimary(expression: expression) + "?"
      case .zeroOrMore(let expression):
        return self.formatPrimary(expression: expression) + "*"
      case .oneOrMore(let expression):
        return self.formatPrimary(expression: expression) + "+"
      case .`repeat`(let min, let max, let expression):
        switch (min, max) {
        case let (n?, nil):
          if n == 0 {
            return self.format(expression: .zeroOrMore(expression))
          } else {
            let required = Expression.concat(Array(repeating: expression, count: n))
            let expanded: Expression = .concat([required, .zeroOrMore(expression)])
            return self.format(expression: expanded.simplified ?? .empty)
          }
        case let (nil, n?):
          if n == 0 {
            return ""
          } else {
            var choices: [Expression] = [.empty]
            for i in 1...n {
              choices.append(Expression.concat(Array(repeating: expression, count: i)))
            }
            let expanded: Expression = .choice(choices)
            return self.format(expression: expanded.simplified ?? .empty)
          }
        case let (m?, n?) where m == n:
          if m == 0 {
            return ""
          }
          let expanded = Expression.concat(Array(repeating: expression, count: m))
          return self.format(expression: expanded.simplified ?? .empty)
        case let (m?, n?):
          let required = Expression.concat(Array(repeating: expression, count: m))
          let additionalMax = n - m
          var additionalChoices: [Expression] = [.empty]
          for i in 1...additionalMax {
            additionalChoices.append(Expression.concat(Array(repeating: expression, count: i)))
          }
          let optionalAdditional = Expression.optional(Expression.choice(additionalChoices))
          let expanded: Expression = .concat([required, optionalAdditional])
          return self.format(expression: expanded.simplified ?? .empty)
        default:
          return ""
        }
      case .group(let expression):
        return "(\(self.format(expression: expression)))"
      case .characterGroup(let characterGroup):
        return self.format(characterGroup: characterGroup)
      case .ref(let symbol):
        return symbol.rawValue
      case .terminal(let terminal):
        return self.format(terminal: terminal)
      }
    }

    private func formatPrimary(expression: Expression) -> String {
      if expression.isPrimary {
        self.format(expression: expression)
      } else {
        "(\(self.format(expression: expression)))"
      }
    }

    private func format(terminal: Terminal) -> String {
      let escaped = terminal.value.reduce(into: "") { result, character in
        switch character {
        case "\\":
          result += "\\\\"
        case #"""#:
          result += #"\""#
        default:
          result.append(character)
        }
      }

      return "\"" + escaped + "\""
    }

    private func format(characterGroup: CharacterGroup) -> String {
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
          switch predefined {
          case .digit:
            result.append("\\d")
          case .nonDigit:
            result.append("\\D")
          case .word:
            result.append("\\w")
          case .nonWord:
            result.append("\\W")
          case .whitespace:
            result.append("\\s")
          case .nonWhitespace:
            result.append("\\S")
          case .wildcard:
            result.append(".")
          }
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
  }
}

extension Grammar.Formatter where Self == Grammar.W3CEBNFFormatter {
  public static var w3cEbnf: Grammar.W3CEBNFFormatter {
    Grammar.W3CEBNFFormatter()
  }
}
