extension Grammar {
  public struct WirthEBNFFormatter: Formatter {
    public init() {}

    public func format(rule: Rule) throws -> String {
      let expression = rule.expression.simplified
      if expression == .empty {
        return ""
      }
      if case .custom = expression {
        throw UnsupportedExpressionError.customExpression
      }
      let formatted = try self.format(expression: expression)
      if formatted.isEmpty {
        return ""
      }
      return "\(rule.symbol.rawValue) = \(formatted) ."
    }

    private func format(expression: Expression) throws -> String {
      switch expression {
      case .empty:
        return ""
      case .concat(let expressions):
        return
          try expressions
          .map { expression in
            switch expression {
            case .choice, .optional:
              "(\(try self.format(expression: expression)))"
            default:
              try self.format(expression: expression)
            }
          }
          .joined(separator: " ")
      case .choice(let expressions):
        return try expressions.map { try self.format(expression: $0) }.joined(separator: " | ")
      case .optional(let expression):
        return "[\(try self.format(expression: expression))]"
      case .`repeat`(let repeatExpr):
        if repeatExpr.isZeroOrMore {
          return "{\(try self.format(expression: repeatExpr.innerExpression))}"
        }
        if repeatExpr.isOneOrMore {
          let formatted = try self.format(expression: repeatExpr.innerExpression)
          let firstElement: String
          if repeatExpr.innerExpression.isPrimary {
            firstElement = formatted
          } else {
            firstElement = "(\(formatted))"
          }
          return "\(firstElement) {\(formatted)}"
        }
        let innerExpression = repeatExpr.innerExpression
        switch (repeatExpr.min, repeatExpr.max) {
        case (let n?, nil):
          if n == 0 {
            return try self.format(expression: Repeat(min: 0, max: nil, innerExpression).expression)
          } else {
            let required = Expression.concat(Array(repeating: innerExpression, count: n))
            let expanded: Expression = .concat([
              required, Repeat(min: 0, max: nil, innerExpression).expression
            ])
            return try self.format(expression: expanded.simplified)
          }
        case (nil, let n?):
          if n == 0 {
            return ""
          } else {
            var choices: [Expression] = [.empty]
            for i in 1...n {
              choices.append(Expression.concat(Array(repeating: innerExpression, count: i)))
            }
            let expanded: Expression = .choice(choices)
            return try self.format(expression: expanded.simplified)
          }
        case (let m?, let n?) where m == n:
          if m == 0 {
            return ""
          }
          let expanded = Expression.concat(Array(repeating: innerExpression, count: m))
          return try self.format(expression: expanded.simplified)
        case (let m?, let n?):
          let required = Expression.concat(Array(repeating: innerExpression, count: m))
          let additionalMax = n - m
          var additionalChoices: [Expression] = [.empty]
          for i in 1...additionalMax {
            additionalChoices.append(Expression.concat(Array(repeating: innerExpression, count: i)))
          }
          let optionalAdditional = Expression.optional(Expression.choice(additionalChoices))
          let expanded: Expression = .concat([required, optionalAdditional])
          return try self.format(expression: expanded.simplified)
        default:
          return ""
        }
      case .group(let expression):
        return "(\(try self.format(expression: expression)))"
      case .characterGroup(let characterGroup):
        return try self.format(characterGroup: characterGroup)
      case .ref(let symbol):
        return symbol.rawValue
      case .terminal(let terminal):
        return self.format(terminal: terminal)
      case .custom:
        return ""
      }
    }

    private func format(terminal: Terminal) -> String {
      let escaped = terminal.value.reduce(into: "") { result, character in
        switch character {
        case "\\":
          result += "\\\\"
        case "'":
          result += "\\'"
        default:
          result.append(character)
        }
      }

      return "'" + escaped + "'"
    }

    private func format(characterGroup: CharacterGroup) throws -> String {
      if characterGroup.isNegated {
        throw UnsupportedExpressionError("Negated character groups are not supported")
      }

      var terminals: [String] = []

      for member in characterGroup.members {
        switch member {
        case .character(let char):
          terminals.append(self.format(terminal: Terminal(String(char))))
        case .range(let start, let end):
          guard let startInt = start.asciiValue, let endInt = end.asciiValue else {
            throw UnsupportedExpressionError("Non-ASCII character ranges are not supported")
          }
          for code in startInt...endInt {
            let char = Character(UnicodeScalar(code))
            terminals.append(self.format(terminal: Terminal(String(char))))
          }
        case .escaped(let escape):
          let escapedStr = self.escapedString(for: escape)
          terminals.append(self.format(terminal: Terminal(escapedStr)))
        case .hex(let codePoint):
          guard let scalar = UnicodeScalar(codePoint) else {
            throw UnsupportedExpressionError("Invalid Unicode code point")
          }
          terminals.append(self.format(terminal: Terminal(String(Character(scalar)))))
        case .hexRange(let start, let end):
          for code in start...end {
            guard let scalar = UnicodeScalar(code) else {
              throw UnsupportedExpressionError("Invalid Unicode code point")
            }
            terminals.append(self.format(terminal: Terminal(String(Character(scalar)))))
          }
        }
      }

      return terminals.joined(separator: " | ")
    }

    private func escapedString(for escape: CharacterGroup.EscapeSequence) -> String {
      switch escape {
      case .backslash:
        "\\"
      case .pipe:
        "|"
      case .period:
        "."
      case .hyphen:
        "-"
      case .caret:
        "^"
      case .question:
        "?"
      case .asterisk:
        "*"
      case .plus:
        "+"
      case .leftBrace:
        "{"
      case .rightBrace:
        "}"
      case .leftParen:
        "("
      case .rightParen:
        ")"
      case .leftBracket:
        "["
      case .rightBracket:
        "]"
      case .newline:
        "\n"
      case .carriageReturn:
        "\r"
      case .tab:
        "\t"
      }
    }
  }
}

extension Grammar.Formatter where Self == Grammar.WirthEBNFFormatter {
  public static var wirthEbnf: Grammar.WirthEBNFFormatter {
    Grammar.WirthEBNFFormatter()
  }
}
