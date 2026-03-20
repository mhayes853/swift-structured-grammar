extension Grammar {
  public struct GBNFFormatter: RuleFormatter {
    public init() {}

    public func format(rule: Rule) throws -> String {
      let expression = rule.expression.simplified
      if case .special = expression {
        throw UnsupportedExpressionError("Special sequences are not supported")
      }
      if case .custom = expression {
        throw UnsupportedExpressionError.customExpression
      }
      return "\(rule.symbol.rawValue) ::= \(try self.format(expression: expression))"
    }

    private func format(expression: Expression) throws -> String {
      switch expression {
      case .epsilon:
        return "\"\""
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
        let inner = try self.formatPrimary(expression: repeatExpr.innerExpression)
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
        return "(\(try self.format(expression: expression)))"
      case .characterGroup(let characterGroup):
        return try self.format(characterGroup: characterGroup)
      case .ref(let ref):
        return ref.symbol.rawValue
      case .special:
        return ""
      case .terminal(let terminal):
        return try self.format(terminal: terminal)
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

    private func format(terminal: Terminal) throws -> String {
      try terminal.formatted(
        options: Terminal.FormatOptions(
          quote: "\"",
          escapeSequences: true,
          hexFormat: .gbnf
        )
      )
    }

    private func format(characterGroup: CharacterGroup) throws -> String {
      try characterGroup.formatted(
        options: CharacterGroup.FormatOptions(
          hexFormat: .gbnf,
          useShorthands: false,
          expandRanges: true
        )
      )
    }
  }
}

extension Grammar.RuleFormatter where Self == Grammar.GBNFFormatter {
  public static var gbnf: Grammar.GBNFFormatter {
    Grammar.GBNFFormatter()
  }
}
