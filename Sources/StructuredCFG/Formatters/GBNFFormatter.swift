extension Grammar {
  public struct GBNFFormatter: Formatter {
    public init() {}

    public func format(rule: Rule) throws -> String {
      let expression = rule.expression.simplified
      if case .special = expression {
        throw UnsupportedExpressionError("Special sequences are not supported")
      }
      if case .custom = expression {
        throw UnsupportedExpressionError.customExpression
      }
      return "\(rule.symbol.rawValue) ::= \(self.format(expression: expression))"
    }

    private func format(expression: Expression) -> String {
      switch expression {
      case .epsilon:
        return "\"\""
      case .concat(let expressions):
        return
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
        return expressions.map { self.format(expression: $0) }.joined(separator: " | ")
      case .optional(let expression):
        return self.formatPrimary(expression: expression) + "?"
      case .`repeat`(let repeatExpr):
        if repeatExpr.isZeroOrMore {
          return self.formatPrimary(expression: repeatExpr.innerExpression) + "*"
        }
        if repeatExpr.isOneOrMore {
          return self.formatPrimary(expression: repeatExpr.innerExpression) + "+"
        }
        let inner = self.formatPrimary(expression: repeatExpr.innerExpression)
        switch (repeatExpr.min, repeatExpr.max) {
        case (let m?, let n?) where m == n:
          return inner + "{\(m)}"
        case (let m?, nil):
          return inner + "{\(m),}"
        case (nil, let n?):
          return inner + "{0,\(n)}"
        case (let m?, let n?):
          return inner + "{\(m),\(n)}"
        default:
          preconditionFailure("Range must have at least one bound")
        }
      case .group(let expression):
        return "(\(self.format(expression: expression)))"
      case .characterGroup(let characterGroup):
        return self.format(characterGroup: characterGroup)
      case .ref(let ref):
        return ref.symbol.rawValue
      case .special:
        return ""
      case .terminal(let terminal):
        return self.format(terminal: terminal)
      case .custom:
        return ""
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
      let escaped = terminal.parts.reduce(into: "") { result, part in
        switch part {
        case .string(let string):
          result += self.escape(string)
        case .hex(let scalars):
          result += scalars.reduce(into: "") { hexResult, scalar in
            hexResult += "\\x"
            hexResult += String(scalar.value, radix: 16)
          }
        }
      }

      return "\"" + escaped + "\""
    }

    private func escape(_ string: String) -> String {
      string.reduce(into: "") { result, character in
        switch character {
        case "\\":
          result += "\\\\"
        case "\"":
          result += "\\\""
        default:
          result.append(character)
        }
      }
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
        case .escaped(let escape):
          result += self.format(escape: escape)
        case .hex(let scalar):
          result += "\\x"
          result += String(scalar.value, radix: 16)
        case .hexRange(let start, let end):
          result += "\\x"
          result += String(start.value, radix: 16)
          result += "-\\x"
          result += String(end.value, radix: 16)
        }
      }

      result.append("]")
      return result
    }

    private func format(escape: CharacterGroup.EscapeSequence) -> String {
      switch escape {
      case .backslash:
        "\\\\"
      case .pipe:
        "\\|"
      case .period:
        "\\."
      case .hyphen:
        "\\-"
      case .caret:
        "\\^"
      case .question:
        "\\?"
      case .asterisk:
        "\\*"
      case .plus:
        "\\+"
      case .leftBrace:
        "\\{"
      case .rightBrace:
        "\\}"
      case .leftParen:
        "\\("
      case .rightParen:
        "\\)"
      case .leftBracket:
        "\\["
      case .rightBracket:
        "\\]"
      case .newline:
        "\\n"
      case .carriageReturn:
        "\\r"
      case .tab:
        "\\t"
      }
    }
  }
}

extension Grammar.Formatter where Self == Grammar.GBNFFormatter {
  public static var gbnf: Grammar.GBNFFormatter {
    Grammar.GBNFFormatter()
  }
}
