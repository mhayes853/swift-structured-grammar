extension Grammar {
  public struct W3CEBNFFormatter: RuleFormatter {
    public enum Quoting: Sendable {
      case single
      case double
    }

    public var quoting = Quoting.double

    public init(quoting: Quoting = .double) {
      self.quoting = quoting
    }

    public func format(rule: Rule) throws -> String {
      let expression = rule.expression.simplified
      if expression == .epsilon {
        throw UnsupportedExpressionError("Epsilon expressions are not supported")
      }
      if case .special = expression {
        throw UnsupportedExpressionError("Special sequences are not supported")
      }
      if case .custom = expression {
        throw UnsupportedExpressionError.customExpression
      }
      let formatted = try self.format(expression: expression)
      if formatted.isEmpty {
        return ""
      }
      return "\(rule.symbol.rawValue) ::= \(formatted)"
    }

    private func format(expression: Expression) throws -> String {
      switch expression {
      case .epsilon:
        throw UnsupportedExpressionError("Epsilon expressions are not supported")
      case .concat(let expressions):
        return
          try expressions
          .map { expression in
            if case .choice = expression {
              "(\(try self.format(expression: expression)))"
            } else {
              try self.format(expression: expression)
            }
          }
          .joined(separator: " ")
      case .choice(let expressions):
        return try expressions.map { try self.format(expression: $0) }.joined(separator: " | ")
      case .optional(let expression):
        return try self.formatPrimary(expression: expression) + "?"
      case .`repeat`(let repeatExpr):
        if repeatExpr.isZeroOrMore {
          return try self.formatPrimary(expression: repeatExpr.innerExpression) + "*"
        }
        if repeatExpr.isOneOrMore {
          return try self.formatPrimary(expression: repeatExpr.innerExpression) + "+"
        }
        let innerExpression = repeatExpr.innerExpression
        switch (repeatExpr.min, repeatExpr.max) {
        case (let n?, nil):
          if n == 0 {
            return try self.formatPrimary(expression: innerExpression) + "*"
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
            var choices: [Expression] = []
            for i in 1...n {
              choices.append(Expression.concat(Array(repeating: innerExpression, count: i)))
            }
            let union = Expression.choice(choices)
            let expanded = Expression.optional(union)
            return try self.format(expression: expanded)
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
          var additionalChoices: [Expression] = []
          for i in 1...additionalMax {
            additionalChoices.append(Expression.concat(Array(repeating: innerExpression, count: i)))
          }
          let optionalAdditional: Expression
          if additionalChoices.isEmpty {
            optionalAdditional = .epsilon
          } else if additionalChoices.count == 1 {
            optionalAdditional = .optional(additionalChoices[0])
          } else {
            optionalAdditional = .optional(Expression.choice(additionalChoices))
          }
          let expanded: Expression = .concat([required, optionalAdditional])
          return try self.format(expression: expanded.simplified)
        default:
          return ""
        }
      case .group(let expression):
        return "(\(try self.format(expression: expression)))"
      case .characterGroup(let characterGroup):
        return characterGroup.formatted(options: CharacterGroup.FormatOptions(hexFormat: .w3c))
      case .ref(let ref):
        return ref.symbol.rawValue
      case .special:
        throw UnsupportedExpressionError("Special sequences are not supported")
      case .terminal(let terminal):
        return self.format(terminal: terminal)
      case .custom:
        return ""
      }
    }

    private func formatPrimary(expression: Expression) throws -> String {
      if expression.isPrimary {
        try self.format(expression: expression)
      } else {
        "(\(try self.format(expression: expression)))"
      }
    }

    private func format(terminal: Terminal) -> String {
      if terminal.parts.isEmpty {
        let quote = self.quoting == .double ? "\"" : "'"
        return quote + quote
      }

      return terminal.parts.map { self.format(terminalPart: $0) }.joined()
    }

    private func format(terminalPart: Terminal.Part) -> String {
      switch terminalPart {
      case .string(let string):
        return self.quote(string)
      case .hex(let scalars):
        return scalars.reduce(into: "") { result, scalar in
          result += "#x"
          result += String(scalar.value, radix: 16)
        }
      }
    }

    private func quote(_ string: String) -> String {
      let escaped: String
      switch self.quoting {
      case .double:
        escaped = string.reduce(into: "") { result, character in
          switch character {
          case "\\":
            result += "\\\\"
          case "\"":
            result += #"\""#
          default:
            result.append(character)
          }
        }
      case .single:
        escaped = string.reduce(into: "") { result, character in
          switch character {
          case "\\":
            result += "\\\\"
          case "'":
            result += #"\'"#
          default:
            result.append(character)
          }
        }
      }

      let quote = self.quoting == .double ? "\"" : "'"
      return quote + escaped + quote
    }

  }
}

extension Grammar.RuleFormatter where Self == Grammar.W3CEBNFFormatter {
  public static var w3cEbnf: Grammar.W3CEBNFFormatter {
    Grammar.W3CEBNFFormatter()
  }

  public static func w3cEbnf(
    quoting: Grammar.W3CEBNFFormatter.Quoting = .double
  ) -> Grammar.W3CEBNFFormatter {
    Grammar.W3CEBNFFormatter(quoting: quoting)
  }
}
