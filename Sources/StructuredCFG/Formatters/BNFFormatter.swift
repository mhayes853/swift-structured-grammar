extension Grammar {
  /// Formats grammar rules using classic Backus-Naur Form.
  public struct BNFFormatter: StatementFormatter {
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

    /// The style used for formatted comments.
    public var commentStyle = CommentStyle.block

    /// Creates a BNF formatter.
    ///
    /// - Parameter commentStyle: The comment style used for formatted comments.
    public init(commentStyle: CommentStyle = .block) {
      self.commentStyle = commentStyle
    }

    /// Formats a single grammar statement.
    ///
    /// - Parameter statement: The statement to format.
    /// - Returns: A textual representation of `statement`.
    public func format(statement: Statement) throws -> String {
      switch statement {
      case .rule(let rule):
        return try self.format(rule: rule)
      case .comment(let comment):
        return comment.formatted(style: self.commentStyle.sharedStyle)
      case .custom:
        throw UnsupportedStatementError.customStatement
      }
    }

    private func format(rule: Rule) throws -> String {
      let rootSymbol = rule.symbol
      let (alternatives, helperLines) = try self.expand(
        expression: rule.expression.simplified,
        rootSymbol: rootSymbol
      )

      var lines = [String]()
      lines.append("<\(rootSymbol.rawValue)> ::= \(try self.formatAlternatives(alternatives))")
      lines.append(contentsOf: helperLines)
      return lines.joined(separator: "\n")
    }

    private enum Element: Hashable, Sendable {
      case symbol(Symbol)
      case terminal(Terminal)
    }

    private struct ExpansionContext {
      var helperCounter = 0
      var helperRules = [String]()
      let rootSymbol: Symbol
    }

    private func expand(
      expression: Expression,
      rootSymbol: Symbol
    ) throws -> ([[Element]], [String]) {
      var context = ExpansionContext(rootSymbol: rootSymbol)
      let elements = try self.expand(expression: expression, context: &context)
      return (elements, context.helperRules)
    }

    private func expand(
      expression: Expression,
      context: inout ExpansionContext
    ) throws -> [[Element]] {
      switch expression {
      case .epsilon:
        return [[]]
      case .concat(let expressions):
        return try expressions.reduce(into: [[]]) { partialResult, expression in
          let next = try self.expand(expression: expression, context: &context)
          partialResult = self.concatenate(partialResult, next)
        }
      case .choice(let expressions):
        return try expressions.flatMap { try self.expand(expression: $0, context: &context) }
      case .optional(let expression):
        return [[]] + (try self.expand(expression: expression, context: &context))
      case .repeat(let repeatExpression):
        return try self.expand(repeatExpression: repeatExpression, context: &context)
      case .group(let expression):
        return try self.expand(expression: expression, context: &context)
      case .characterGroup(let group):
        return try self.expand(characterGroup: group, context: &context)
      case .ref(let ref):
        return [[.symbol(ref.symbol)]]
      case .terminal(let terminal):
        return [[.terminal(terminal)]]
      case .special:
        throw UnsupportedExpressionError("Special sequences are not supported")
      case .custom:
        throw UnsupportedExpressionError.customExpression
      }
    }

    private func expand(
      repeatExpression: Repeat,
      context: inout ExpansionContext
    ) throws -> [[Element]] {
      let inner = try self.expand(expression: repeatExpression.innerExpression, context: &context)

      switch (repeatExpression.min, repeatExpression.max) {
      case (nil, nil):
        throw UnsupportedExpressionError("Repeat ranges must have at least one bound")
      case (let min?, let max?) where min == max:
        return self.repeated(inner, count: min)
      case (let min?, nil):
        if min == 0 {
          let symbol = self.nextHelperSymbol(context: &context)
          let recursiveAlternatives = [[]] + self.concatenate(inner, [[.symbol(symbol)]])
          context.helperRules.append(
            "<\(symbol.rawValue)> ::= \(try self.formatAlternatives(recursiveAlternatives))"
          )
          return [[.symbol(symbol)]]
        }

        let zeroOrMore = try self.expand(
          repeatExpression: Repeat(min: 0, max: nil, repeatExpression.innerExpression),
          context: &context
        )
        return self.concatenate(self.repeated(inner, count: min), zeroOrMore)
      case (nil, let max?):
        return self.expandAtMost(inner: inner, max: max, context: &context)
      case (let min?, let max?):
        let required = self.repeated(inner, count: min)
        let optionalTail = self.expandAtMost(inner: inner, max: max - min, context: &context)
        return self.concatenate(required, optionalTail)
      }
    }

    private func expandAtMost(
      inner: [[Element]],
      max: Int,
      context: inout ExpansionContext
    ) -> [[Element]] {
      guard max > 0 else {
        return [[]]
      }

      let alternatives = (1...max).flatMap { self.repeated(inner, count: $0) }
      return [[]] + alternatives
    }

    private func expand(
      characterGroup: CharacterGroup,
      context: inout ExpansionContext
    ) throws -> [[Element]] {
      if characterGroup.isNegated {
        throw UnsupportedExpressionError("Negated character groups are not supported")
      }

      return try characterGroup.members.flatMap { member in
        try self.expand(characterGroupMember: member, context: &context)
      }
    }

    private func expand(
      characterGroupMember member: CharacterGroup.Member,
      context: inout ExpansionContext
    ) throws -> [[Element]] {
      switch member {
      case .character(let character):
        return [[.terminal(self.terminal(from: character))]]
      case .range(let start, let end):
        guard let startValue = self.asciiValue(for: start), let endValue = self.asciiValue(for: end)
        else {
          throw UnsupportedExpressionError("Non-ASCII character ranges are not supported")
        }
        return (startValue...endValue)
          .map { value in
            [.terminal(Terminal(Character(Unicode.Scalar(value)!)))]
          }
      case .escaped(let escape):
        return [[.terminal(Terminal(self.string(for: escape)))]]
      }
    }

    private func terminal(from character: Terminal.Character) -> Terminal {
      switch character {
      case .character(let character):
        return Terminal(character)
      case .hex(let scalar):
        return Terminal(Character(scalar))
      case .unicode(let scalar):
        return Terminal(Character(scalar))
      }
    }

    private func asciiValue(for character: Terminal.Character) -> UInt32? {
      switch character {
      case .character(let character):
        return character.asciiValue.map(UInt32.init)
      case .hex(let scalar), .unicode(let scalar):
        guard scalar.isASCII else { return nil }
        return scalar.value
      }
    }

    private func nextHelperSymbol(context: inout ExpansionContext) -> Symbol {
      context.helperCounter += 1
      return Symbol("\(context.rootSymbol.rawValue)__bnf_\(context.helperCounter)")
    }

    private func repeated(_ alternatives: [[Element]], count: Int) -> [[Element]] {
      if count == 0 {
        return [[]]
      }

      return (0..<count)
        .reduce([[]]) { partialResult, _ in
          self.concatenate(partialResult, alternatives)
        }
    }

    private func concatenate(_ lhs: [[Element]], _ rhs: [[Element]]) -> [[Element]] {
      lhs.flatMap { left in
        rhs.map { right in
          left + right
        }
      }
    }

    private func string(for escape: CharacterGroup.EscapeSequence) -> String {
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

    private func formatAlternatives(_ alternatives: [[Element]]) throws -> String {
      try alternatives
        .map { sequence in
          if sequence.isEmpty {
            "\"\""
          } else {
            try sequence.map { try self.format(element: $0) }.joined(separator: " ")
          }
        }
        .joined(separator: " | ")
    }

    private func format(element: Element) throws -> String {
      switch element {
      case .symbol(let symbol):
        "<\(symbol.rawValue)>"
      case .terminal(let terminal):
        try self.format(terminal: terminal)
      }
    }

    private func format(terminal: Terminal) throws -> String {
      let escaped = try terminal.characters.reduce(into: "") { result, character in
        switch character {
        case .character(let character):
          result += try self.escape(String(character))
        case .hex(let scalar), .unicode(let scalar):
          result += try self.escape(String(scalar))
        }
      }
      return "\"" + escaped + "\""
    }

    private func escape(_ string: String) throws -> String {
      try string.reduce(into: "") { result, character in
        switch character {
        case "\\":
          throw UnsupportedExpressionError("Backslashes are not supported in BNF terminals")
        case "\"":
          result += "\"\""
        case "\n":
          throw UnsupportedExpressionError("Control characters are not supported in BNF terminals")
        case "\r":
          throw UnsupportedExpressionError("Control characters are not supported in BNF terminals")
        case "\t":
          throw UnsupportedExpressionError("Control characters are not supported in BNF terminals")
        default:
          result.append(character)
        }
      }
    }
  }
}

extension Grammar.StatementFormatter where Self == Grammar.BNFFormatter {
  /// A BNF formatter.
  public static var bnf: Grammar.BNFFormatter {
    Grammar.BNFFormatter()
  }

  /// Creates a BNF formatter.
  ///
  /// - Parameter commentStyle: The comment style used for formatted comments.
  /// - Returns: A configured BNF formatter.
  public static func bnf(
    commentStyle: Grammar.BNFFormatter.CommentStyle = .block
  ) -> Grammar.BNFFormatter {
    Grammar.BNFFormatter(commentStyle: commentStyle)
  }
}
