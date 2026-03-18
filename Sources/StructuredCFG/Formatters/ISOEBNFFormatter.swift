extension Grammar {
  public struct ISOEBNFFormatter: Formatter {
    public enum Quoting: Sendable {
      case single
      case double
    }

    public enum DefinitionSeparator: String, Sendable {
      case pipe = "|"
      case slash = "/"
      case bang = "!"
    }

    public enum Terminator: String, Sendable {
      case semicolon = ";"
      case period = "."
    }

    public var definitionSeparator = DefinitionSeparator.pipe
    public var terminator = Terminator.semicolon
    public var quoting = Quoting.single

    public init(
      definitionSeparator: DefinitionSeparator = .pipe,
      terminator: Terminator = .semicolon,
      quoting: Quoting = .single
    ) {
      self.definitionSeparator = definitionSeparator
      self.terminator = terminator
      self.quoting = quoting
    }

    public func format(rule: Rule) throws -> String {
      let expression = rule.expression.simplified
      if expression == .empty {
        return ""
      }
      if case .custom = expression {
        throw UnsupportedExpressionError.customExpression
      }
      let formatted = try self.format(expression: expression)
      let rightHandSide = formatted.isEmpty ? " " : " \(formatted)"
      return "\(rule.symbol.rawValue) =\(rightHandSide)\(self.terminator.rawValue)"
    }

    private func format(expression: Expression) throws -> String {
      switch expression {
      case .empty, .emptySequence:
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
        let separator = " \(self.definitionSeparator.rawValue) "
        return try expressions.map { try self.format(expression: $0) }.joined(separator: separator)
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
            return ""
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
          return try (0...n)
            .map { count in
              let formatted = try self.formatPrimary(expression: innerExpression)
              switch count {
              case 0:
                return ""
              case 1:
                return formatted
              default:
                return "\(count) * \(formatted)"
              }
            }
            .joined(separator: " \(self.definitionSeparator.rawValue) ")
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
        return "(\(try self.format(expression: expression)))"
      case .characterGroup(let characterGroup):
        return try self.format(characterGroup: characterGroup)
      case .ref(let ref):
        return ref.symbol.rawValue
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
      self.quote(terminal.string)
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

    private func format(characterGroup: CharacterGroup) throws -> String {
      if characterGroup.isNegated {
        throw UnsupportedExpressionError("Negated character groups are not supported")
      }

      var terminals = [String]()

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
          terminals.append(self.format(terminal: Terminal(self.escapedString(for: escape))))
        case .hex(let scalar):
          terminals.append(self.format(terminal: Terminal(String(Character(scalar)))))
        case .hexRange(let start, let end):
          for code in start.value...end.value {
            guard let scalar = Unicode.Scalar(code) else {
              throw UnsupportedExpressionError("Invalid Unicode code point")
            }
            terminals.append(self.format(terminal: Terminal(String(Character(scalar)))))
          }
        }
      }

      let separator = " \(self.definitionSeparator.rawValue) "
      return terminals.joined(separator: separator)
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

extension Grammar.Formatter where Self == Grammar.ISOEBNFFormatter {
  public static var isoEbnf: Grammar.ISOEBNFFormatter {
    Grammar.ISOEBNFFormatter()
  }

  public static func isoEbnf(
    definitionSeparator: Grammar.ISOEBNFFormatter.DefinitionSeparator = .pipe,
    terminator: Grammar.ISOEBNFFormatter.Terminator = .semicolon,
    quoting: Grammar.ISOEBNFFormatter.Quoting = .single
  ) -> Grammar.ISOEBNFFormatter {
    Grammar.ISOEBNFFormatter(
      definitionSeparator: definitionSeparator,
      terminator: terminator,
      quoting: quoting
    )
  }
}
