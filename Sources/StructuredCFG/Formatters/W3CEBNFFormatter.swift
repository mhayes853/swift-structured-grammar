extension Grammar {
  /// Formats grammar rules using the W3C EBNF dialect.
  public struct W3CEBNFFormatter: StatementFormatter {
    /// Controls how comments are emitted.
    public enum CommentStyle: Sendable {
      /// Emit block comments.
      case block
      /// Emit ISO-style comments.
      case iso
      /// Emit single-line comments.
      case line
      /// Omit comments entirely.
      case none
    }

    /// Controls how literal terminals are quoted.
    public enum Quoting: Sendable {
      /// Use single quotes.
      case single
      /// Use double quotes.
      case double
    }

    /// The quoting style used for terminal literals.
    public var quoting = Quoting.double

    /// The style used for formatted comments.
    public var commentStyle = CommentStyle.block

    /// Creates a W3C EBNF formatter.
    ///
    /// - Parameter quoting: The quoting style used for literal terminals.
    /// - Parameter commentStyle: The comment style used for formatted comments.
    public init(quoting: Quoting = .double, commentStyle: CommentStyle = .block) {
      self.quoting = quoting
      self.commentStyle = commentStyle
    }

    /// Formats a single grammar statement.
    ///
    /// - Parameter statement: The statement to format.
    /// - Returns: A textual representation of `statement`.
    public func format(statement: Statement) throws -> String {
      switch statement {
      case .rule(let rule):
        try self.format(rule: rule)
      case .comment(let comment):
        comment.formatted(style: self.commentStyle.sharedStyle)
      case .custom:
        throw UnsupportedStatementError.customStatement
      }
    }

    private func format(rule: Rule) throws -> String {
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
            let choices = (1...n)
              .map { Expression.concat(Array(repeating: innerExpression, count: $0)) }
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
          let additionalChoices = (1...additionalMax)
            .map { Expression.concat(Array(repeating: innerExpression, count: $0)) }
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
        return try characterGroup.formatted(
          options: CharacterGroup.FormatOptions(
            hexFormat: .w3c,
            allCharactersContent: "#x9#xA#xD#x20-#xD7FF#xE000-#xFFFD#x10000-#x10FFFF"
          )
        )
      case .ref(let ref):
        return ref.symbol.rawValue
      case .special:
        throw UnsupportedExpressionError("Special sequences are not supported")
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
      if terminal.characters.isEmpty {
        let quote = self.quoting == .double ? "\"" : "'"
        return quote + quote
      }

      var result = ""
      var pendingLiteral = ""

      func flushLiteral() {
        guard !pendingLiteral.isEmpty else { return }
        result += self.quote(pendingLiteral)
        pendingLiteral = ""
      }

      for character in terminal.characters {
        switch character {
        case .character(let character):
          switch (self.quoting, character) {
          case (.double, "\""):
            flushLiteral()
            result += "#x22"
          case (.single, "'"):
            flushLiteral()
            result += "#x27"
          default:
            pendingLiteral.append(character)
          }
        case .hex, .unicode:
          flushLiteral()
          result += try self.format(terminalCharacter: character)
        }
      }

      flushLiteral()
      return result
    }

    private func format(terminalCharacter: Terminal.Character) throws -> String {
      switch terminalCharacter {
      case .character(let character):
        return self.quote(String(character))
      case .hex(let scalar):
        return "#x" + String(scalar.value, radix: 16)
      case .unicode(let scalar):
        return self.quote(String(scalar))
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
          default:
            result.append(character)
          }
        }
      case .single:
        escaped = string.reduce(into: "") { result, character in
          switch character {
          case "\\":
            result += "\\\\"
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

extension Grammar.StatementFormatter where Self == Grammar.W3CEBNFFormatter {
  /// A W3C EBNF formatter that uses double quotes for terminals.
  public static var w3cEbnf: Grammar.W3CEBNFFormatter {
    Grammar.W3CEBNFFormatter()
  }

  /// Creates a W3C EBNF formatter.
  ///
  /// - Parameter quoting: The quoting style used for literal terminals.
  /// - Parameter commentStyle: The comment style used for formatted comments.
  /// - Returns: A configured W3C EBNF formatter.
  public static func w3cEbnf(
    quoting: Grammar.W3CEBNFFormatter.Quoting = .double,
    commentStyle: Grammar.W3CEBNFFormatter.CommentStyle = .block
  ) -> Grammar.W3CEBNFFormatter {
    Grammar.W3CEBNFFormatter(quoting: quoting, commentStyle: commentStyle)
  }
}
