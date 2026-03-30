extension Grammar {
  /// Formats grammar rules using the ISO/IEC 14977 EBNF dialect.
  public struct ISOIECEBNFFormatter: StatementFormatter {
    /// Controls how literal terminals are quoted.
    public enum Quoting: Sendable {
      /// Use single quotes.
      case single
      /// Use double quotes.
      case double
    }

    /// Controls the separator used between alternatives.
    public enum DefinitionSeparator: String, Sendable {
      /// Use `|`.
      case pipe = "|"
      /// Use `/`.
      case slash = "/"
      /// Use `!`.
      case bang = "!"
    }

    /// Controls the terminator used after each rule.
    public enum Terminator: String, Sendable {
      /// Use `;`.
      case semicolon = ";"
      /// Use `.`.
      case period = "."
    }

    /// The separator used between alternatives.
    public var definitionSeparator = DefinitionSeparator.pipe

    /// The terminator used after each rule.
    public var terminator = Terminator.semicolon

    /// The quoting style used for terminal literals.
    public var quoting = Quoting.double

    /// Creates an ISO/IEC EBNF formatter.
    ///
    /// - Parameters:
    ///   - definitionSeparator: The separator used between alternatives.
    ///   - terminator: The terminator used after each rule.
    ///   - quoting: The quoting style used for terminals.
    public init(
      definitionSeparator: DefinitionSeparator = .pipe,
      terminator: Terminator = .semicolon,
      quoting: Quoting = .double
    ) {
      self.definitionSeparator = definitionSeparator
      self.terminator = terminator
      self.quoting = quoting
    }

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
      let expression = rule.expression.simplified
      if case .custom = expression {
        throw UnsupportedExpressionError.customExpression
      }
      let formatted = try self.format(expression: expression)
      let rightHandSide = " " + (formatted.isEmpty ? self.formattedEpsilon() : formatted)
      return "\(self.metaIdentifier(for: rule.symbol)) =\(rightHandSide)\(self.terminator.rawValue)"
    }

    private func format(expression: Expression) throws -> String {
      switch expression {
      case .epsilon:
        return ""
      case .concat(let expressions):
        return
          try expressions.map { expression in
            switch expression {
            case .choice:
              "(\(try self.format(expression: expression)))"
            default:
              try self.format(expression: expression)
            }
          }
          .joined(separator: ", ")
      case .choice(let expressions):
        let formattedExpressions: [String] = try expressions.compactMap { expression in
          let simplifiedExpression = expression.simplified
          let formatted = try self.format(expression: simplifiedExpression)
          guard !formatted.isEmpty else { return nil }
          if simplifiedExpression.isPrimary {
            return formatted
          }
          return "(\(formatted))"
        }
        let containsEpsilon = expressions.contains { expression in
          expression.simplified == .epsilon
        }
        if formattedExpressions.isEmpty {
          return ""
        }
        if containsEpsilon {
          return "[\(formattedExpressions.joined(separator: " \(self.definitionSeparator.rawValue) "))]"
        }
        let separator = " \(self.definitionSeparator.rawValue) "
        return formattedExpressions.joined(separator: separator)
      case .optional(let expression):
        return "[\(try self.format(expression: expression))]"
      case .repeat(let repeatExpr):
        if repeatExpr.isZeroOrMore {
          return "{\(try self.format(expression: repeatExpr.innerExpression))}"
        }
        if repeatExpr.isOneOrMore {
          let formatted = try self.format(expression: repeatExpr.innerExpression)
          let firstElement = repeatExpr.innerExpression.isPrimary ? formatted : "(\(formatted))"
          return "\(firstElement), {\(formatted)}"
        }
        let innerExpression = repeatExpr.innerExpression
        switch (repeatExpr.min, repeatExpr.max) {
        case (let m?, let n?) where m == n:
          if m == 0 {
            return self.formattedEpsilon()
          }
          let formatted = try self.formatPrimary(expression: innerExpression)
          return "\(m) * \(formatted)"
        case (let n?, nil):
          if n == 0 {
            return "{\(try self.format(expression: innerExpression))}"
          }
          let required = Expression.concat(Array(repeating: innerExpression, count: n))
          let expanded: Expression = .concat([
            required, Repeat(min: 0, max: nil, innerExpression).expression
          ])
          return try self.format(expression: expanded.simplified)
        case (nil, let n?):
          if n == 0 {
            return ""
          } else {
            let innerFormatted = try self.formatPrimary(expression: innerExpression)
            let choices: [String] = (1...n)
              .map { count in
                switch count {
                case 1:
                  return innerFormatted
                default:
                  return "\(count) * \(innerFormatted)"
                }
              }
            let unionFormatted = choices.joined(separator: " \(self.definitionSeparator.rawValue) ")
            return "[\(unionFormatted)]"
          }
        case (let m?, let n?):
          let required = Expression.concat(Array(repeating: innerExpression, count: m))
          let additionalMax = n - m
          let requiredFormatted = try self.format(expression: required.simplified)
          if additionalMax == 0 {
            return requiredFormatted
          }
          let additionalFormatted = try (1...additionalMax)
            .map { count in
              let formatted = try self.formatPrimary(expression: innerExpression)
              if count == 1 {
                return formatted
              } else {
                return "\(count) * \(formatted)"
              }
            }
            .joined(separator: " \(self.definitionSeparator.rawValue) ")
          return requiredFormatted + ", [\(additionalFormatted)]"
        default:
          return ""
        }
      case .group(let expression):
        let formatted = try self.format(expression: expression)
        if formatted.isEmpty {
          return ""
        }
        return "(\(formatted))"
      case .characterGroup(let characterGroup):
        return try self.format(characterGroup: characterGroup)
      case .ref(let ref):
        return self.metaIdentifier(for: ref.symbol)
      case .special(let special):
        return "? \(special.value) ?"
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
      let renderedCharacters = terminal.characters.map { self.renderedTerminalCharacter(for: $0) }
      var formattedParts = [String]()
      var currentQuote = renderedCharacters.first?.quote
      var currentString = ""

      for renderedCharacter in renderedCharacters {
        if renderedCharacter.quote != currentQuote, !currentString.isEmpty {
          formattedParts.append(self.quote(currentString, using: currentQuote ?? self.quoting))
          currentString = ""
        }
        currentQuote = renderedCharacter.quote
        currentString += renderedCharacter.string
      }

      if !currentString.isEmpty {
        formattedParts.append(self.quote(currentString, using: currentQuote ?? self.quoting))
      }

      return formattedParts.joined(separator: ", ")
    }

    private enum RenderedTerminalCharacter {
      case quoted(String, Quoting)

      var string: String {
        switch self {
        case .quoted(let string, _):
          string
        }
      }

      var quote: Quoting {
        switch self {
        case .quoted(_, let quote):
          quote
        }
      }
    }

    private func renderedTerminalCharacter(for character: Terminal.Character) -> RenderedTerminalCharacter {
      let string: String
      switch character {
      case .character(let character):
        string = String(character)
      case .hex(let scalar), .unicode(let scalar):
        string = String(scalar)
      }

      if string == #"""# {
        return .quoted(string, .single)
      }
      if string == "'" {
        return .quoted(string, .double)
      }
      return .quoted(string, self.quoting)
    }

    private func quote(_ string: String) -> String {
      self.quote(string, using: self.quoting)
    }

    private func formattedEpsilon() -> String {
      "0 * \(self.quote(""))"
    }

    private func quote(_ string: String, using quoting: Quoting) -> String {
      let escaped: String
      switch quoting {
      case .double:
        escaped = string.reduce(into: "") { result, character in
          switch character {
          case "\n":
            result += "\\n"
          case "\r":
            result += "\\r"
          case "\t":
            result += "\\t"
          default:
            result.append(character)
          }
        }
      case .single:
        escaped = string.reduce(into: "") { result, character in
          switch character {
        case "\n":
          result += "\\n"
        case "\r":
          result += "\\r"
        case "\t":
          result += "\\t"
        case "'":
          result += #"\'"#
        default:
            result.append(character)
          }
        }
      }

      let quote = quoting == .double ? "\"" : "'"
      return quote + escaped + quote
    }

    private func metaIdentifier(for symbol: Symbol) -> String {
      let normalized = symbol.rawValue
        .split(whereSeparator: { character in
          !(character.isLetter || character.isNumber)
        })
        .map(String.init)
        .filter { !$0.isEmpty }
        .joined()

      guard let firstCharacter = normalized.first else {
        return "g"
      }
      if firstCharacter.isLetter {
        return normalized
      }
      return "g" + normalized
    }

    private func format(characterGroup: CharacterGroup) throws -> String {
      if characterGroup.isAllCharacters {
        throw UnsupportedExpressionError("All-character groups are not supported")
      }
      if characterGroup.isNegated {
        throw UnsupportedExpressionError("Negated character groups are not supported")
      }

      guard let members = characterGroup.members else {
        throw UnsupportedExpressionError("Character group members are not available")
      }

      var terminals = [String]()

      for member in members {
        switch member {
        case .character(let character):
          terminals.append(self.format(terminal: self.terminal(from: character)))
        case .range(let start, let end):
          guard let startInt = self.asciiValue(for: start), let endInt = self.asciiValue(for: end) else {
            throw UnsupportedExpressionError("Non-ASCII character ranges are not supported")
          }
          for code in startInt...endInt {
            let char = Character(Unicode.Scalar(code)!)
            terminals.append(self.format(terminal: Terminal(String(char))))
          }
        case .escaped(let escape):
          terminals.append(self.format(terminal: Terminal(self.escapedString(for: escape))))
        }
      }

      let separator = " \(self.definitionSeparator.rawValue) "
      return terminals.joined(separator: separator)
    }

    private func format(comment: Comment) -> String {
      comment.text
        .split(separator: "\n", omittingEmptySubsequences: false)
        .map { "(* \($0) *)" }
        .joined(separator: "\n")
    }

    private func terminal(from character: Terminal.Character) -> Terminal {
      switch character {
      case .character(let character):
        return Terminal(character)
      case .hex(let scalar), .unicode(let scalar):
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

    private func escapedString(for escape: CharacterGroup.EscapeSequence) -> String {
      String(escape.character)
    }
  }
}

extension Grammar.StatementFormatter where Self == Grammar.ISOIECEBNFFormatter {
  /// An ISO/IEC EBNF formatter with default options.
  public static var isoIecEbnf: Grammar.ISOIECEBNFFormatter {
    Grammar.ISOIECEBNFFormatter()
  }

  /// Creates an ISO/IEC EBNF formatter.
  ///
  /// - Parameters:
  ///   - definitionSeparator: The separator used between alternatives.
  ///   - terminator: The terminator used after each rule.
  ///   - quoting: The quoting style used for terminals.
  /// - Returns: A configured ISO/IEC EBNF formatter.
  public static func isoIecEbnf(
    definitionSeparator: Grammar.ISOIECEBNFFormatter.DefinitionSeparator = .pipe,
    terminator: Grammar.ISOIECEBNFFormatter.Terminator = .semicolon,
    quoting: Grammar.ISOIECEBNFFormatter.Quoting = .double
  ) -> Grammar.ISOIECEBNFFormatter {
    Grammar.ISOIECEBNFFormatter(
      definitionSeparator: definitionSeparator,
      terminator: terminator,
      quoting: quoting
    )
  }
}
