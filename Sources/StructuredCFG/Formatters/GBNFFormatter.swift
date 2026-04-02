extension Grammar {
  /// Formats grammar rules using GBNF syntax.
  public struct GBNFFormatter: StatementFormatter {
    /// Creates a GBNF formatter.
    public init() {}

    public func format(statement: Statement) throws -> String {
      switch statement {
      case .rule(let rule):
        return try self.format(rule: rule)
      case .comment(let comment):
        return self.format(comment: comment)
      case .custom:
        throw UnsupportedStatementError.customStatement
      }
    }

    private func format(rule: Rule) throws -> String {
      "\(rule.symbol.rawValue) ::= \(try self.format(expression: rule.expression.simplified))"
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
        throw UnsupportedExpressionError("Special sequences are not supported")
      case .terminal(let terminal):
        return try self.format(terminal: terminal)
      case .custom:
        throw UnsupportedExpressionError.customExpression
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
          expandRanges: true,
          allCharactersContent: #"\u0000-\U0010FFFF"#
        )
      )
    }

    private func format(comment: Comment) -> String {
      comment.text
        .split(separator: "\n", omittingEmptySubsequences: false)
        .map { "# \($0)" }
        .joined(separator: "\n")
    }
  }
}

extension Grammar.StatementFormatter where Self == Grammar.GBNFFormatter {
  /// A GBNF formatter.
  public static var gbnf: Grammar.GBNFFormatter {
    Grammar.GBNFFormatter()
  }
}
