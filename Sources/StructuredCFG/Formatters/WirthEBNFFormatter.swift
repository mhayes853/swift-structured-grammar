import Foundation

extension Grammar {
  public struct WirthEBNFFormatter: Formatter {
    public init() {}

    public func format(production: Production) -> String {
      guard let expression = self.simplified(expression: production.expression) else {
        return ""
      }
      let formatted = self.format(expression: expression)
      if formatted.isEmpty {
        return ""
      }
      return "\(production.symbol.rawValue) = \(formatted) ."
    }

    private func simplified(expression: Expression) -> Expression? {
      switch expression {
      case .empty:
        return nil
      case .concat(let expressions):
        let expressions = expressions.compactMap { self.simplified(expression: $0) }
        switch expressions.count {
        case 0:
          return nil
        case 1:
          return expressions[0]
        default:
          return .concat(expressions)
        }
      case .choice(let expressions):
        let expressions = expressions.compactMap { self.simplified(expression: $0) }
        switch expressions.count {
        case 0:
          return nil
        case 1:
          return expressions[0]
        default:
          return .choice(expressions)
        }
      case .optional(let expression):
        return self.simplified(expression: expression).map(Expression.optional)
      case .zeroOrMore(let expression):
        return self.simplified(expression: expression).map(Expression.zeroOrMore)
      case .oneOrMore(let expression):
        return self.simplified(expression: expression).map(Expression.oneOrMore)
      case .`repeat`(let min, let max, let expression):
        guard let simplified = self.simplified(expression: expression) else {
          return nil
        }
        return .`repeat`(min: min, max: max, expression: simplified)
      case .group(let expression):
        return self.simplified(expression: expression).map(Expression.group)
      case .characterGroup(let characterGroup):
        return .characterGroup(characterGroup)
      case .ref(let symbol):
        return .ref(symbol)
      case .terminal(let terminal):
        return .terminal(terminal)
      }
    }

    private func format(expression: Expression) -> String {
      switch expression {
      case .empty:
        preconditionFailure("Empty expressions must be simplified before formatting.")
      case .concat(let expressions):
        return expressions
          .map { expression in
            switch expression {
            case .choice, .optional:
              "(\(self.format(expression: expression)))"
            default:
              self.format(expression: expression)
            }
          }
          .joined(separator: " ")
      case .choice(let expressions):
        return expressions.map { self.format(expression: $0) }.joined(separator: " | ")
      case .optional(let expression):
        return "[\(self.format(expression: expression))]"
      case .zeroOrMore(let expression):
        return "{\(self.format(expression: expression))}"
      case .oneOrMore(let expression):
        let formatted = self.format(expression: expression)
        let firstElement: String
        if self.isPrimary(expression: expression) {
          firstElement = formatted
        } else {
          firstElement = "(\(formatted))"
        }
        return "\(firstElement) {\(formatted)}"
      case .`repeat`(let min, let max, let expression):
        switch (min, max) {
        case let (n?, nil):
          if n == 0 {
            return self.format(expression: .zeroOrMore(expression))
          } else {
            let required = Expression.concat(Array(repeating: expression, count: n))
            let expanded: Expression = .concat([required, .zeroOrMore(expression)])
            return self.format(expression: self.simplified(expression: expanded) ?? .empty)
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
            return self.format(expression: self.simplified(expression: expanded) ?? .empty)
          }
        case let (m?, n?) where m == n:
          if m == 0 {
            return ""
          }
          let expanded = Expression.concat(Array(repeating: expression, count: m))
          return self.format(expression: self.simplified(expression: expanded) ?? .empty)
        case let (m?, n?):
          let required = Expression.concat(Array(repeating: expression, count: m))
          let additionalMax = n - m
          var additionalChoices: [Expression] = [.empty]
          for i in 1...additionalMax {
            additionalChoices.append(Expression.concat(Array(repeating: expression, count: i)))
          }
          let optionalAdditional = Expression.optional(Expression.choice(additionalChoices))
          let expanded: Expression = .concat([required, optionalAdditional])
          return self.format(expression: self.simplified(expression: expanded) ?? .empty)
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

    private func isPrimary(expression: Expression) -> Bool {
      switch expression {
      case .ref, .group, .terminal, .characterGroup:
        true
      case .empty, .concat, .choice, .optional, .zeroOrMore, .oneOrMore, .`repeat`:
        false
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

    private func format(characterGroup: CharacterGroup) -> String {
      if characterGroup.isNegated {
        fatalError("Negated character groups are not supported in Wirth EBNF formatting.")
      }

      var terminals: [String] = []

      for member in characterGroup.members {
        switch member {
        case .character(let char):
          terminals.append(self.format(terminal: Terminal(String(char))))
        case .range(let start, let end):
          let startInt = start.asciiValue!
          let endInt = end.asciiValue!
          for code in startInt...endInt {
            let char = Character(UnicodeScalar(code))
            terminals.append(self.format(terminal: Terminal(String(char))))
          }
        case .category:
          self.unsupported("Unicode categories")
        case .negatedCategory:
          self.unsupported("Negated categories")
        case .predefined(let predefined):
          terminals.append(contentsOf: self.terminalsForPredefined(predefined))
        case .xmlName:
          self.unsupported("XML name classes")
        case .subtraction:
          self.unsupported("Character group subtraction")
        case .escaped(let escape):
          let escapedStr = self.escapedString(for: escape)
          terminals.append(self.format(terminal: Terminal(escapedStr)))
        }
      }

      return terminals.joined(separator: " | ")
    }

    private func terminalsForPredefined(_ predefined: CharacterGroup.PredefinedClass) -> [String] {
      switch predefined {
      case .digit:
        return (0...9).map { self.format(terminal: Terminal(String($0))) }
      case .nonDigit, .nonWord, .nonWhitespace:
        self.unsupported("Negated predefined classes")
      case .word:
        let wordChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
        return wordChars.map { self.format(terminal: Terminal(String($0))) }
      case .whitespace:
        return [" ", "\t", "\n", "\r"].map { self.format(terminal: Terminal(String($0))) }
      case .wildcard:
        self.unsupported("Wildcard")
      }
    }

    private func unsupported(_ feature: String) -> Never {
      fatalError("\(feature) are not supported in Wirth EBNF formatting.")
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
        "\\n"
      case .carriageReturn:
        "\\r"
      case .tab:
        "\\t"
      }
    }
  }
}

extension Grammar.Formatter where Self == Grammar.WirthEBNFFormatter {
  public static var wirthEbnf: Grammar.WirthEBNFFormatter {
    Grammar.WirthEBNFFormatter()
  }
}
