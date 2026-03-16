import Foundation

extension Grammar {
  public struct WirthEBNFFormatterError: Error, Hashable {
    private enum Kind: Hashable {
      case negatedCharacterGroup
      case unicodeCategory
      case negatedCategory
      case characterGroupSubtraction
      case xmlNameClasses
      case negatedPredefinedClass
      case wildcard
      case customExpression
    }

    private let kind: Kind

    private init(kind: Kind) {
      self.kind = kind
    }

    public static let negatedCharacterGroup = WirthEBNFFormatterError(kind: .negatedCharacterGroup)
    public static let unicodeCategory = WirthEBNFFormatterError(kind: .unicodeCategory)
    public static let negatedCategory = WirthEBNFFormatterError(kind: .negatedCategory)
    public static let characterGroupSubtraction = WirthEBNFFormatterError(
      kind: .characterGroupSubtraction
    )
    public static let xmlNameClasses = WirthEBNFFormatterError(kind: .xmlNameClasses)
    public static let negatedPredefinedClass = WirthEBNFFormatterError(
      kind: .negatedPredefinedClass
    )
    public static let wildcard = WirthEBNFFormatterError(kind: .wildcard)
    public static let customExpression = WirthEBNFFormatterError(kind: .customExpression)
  }

  public struct WirthEBNFFormatter: Formatter {
    public init() {}

    public func format(rule: Rule) throws -> String {
      let expression = rule.expression.simplified
      if expression == .empty {
        return ""
      }
      if case .custom = expression {
        throw Grammar.WirthEBNFFormatterError.customExpression
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
        throw WirthEBNFFormatterError.negatedCharacterGroup
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
          throw WirthEBNFFormatterError.unicodeCategory
        case .negatedCategory:
          throw WirthEBNFFormatterError.negatedCategory
        case .predefined(let predefined):
          terminals.append(contentsOf: try self.terminalsForPredefined(predefined))
        case .xmlName:
          throw WirthEBNFFormatterError.xmlNameClasses
        case .subtraction:
          throw WirthEBNFFormatterError.characterGroupSubtraction
        case .escaped(let escape):
          let escapedStr = self.escapedString(for: escape)
          terminals.append(self.format(terminal: Terminal(escapedStr)))
        }
      }

      return terminals.joined(separator: " | ")
    }

    private func terminalsForPredefined(_ predefined: CharacterGroup.PredefinedClass) throws
      -> [String]
    {
      switch predefined {
      case .digit:
        return (0...9).map { self.format(terminal: Terminal(String($0))) }
      case .nonDigit, .nonWord, .nonWhitespace:
        throw WirthEBNFFormatterError.negatedPredefinedClass
      case .word:
        let wordChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
        return wordChars.map { self.format(terminal: Terminal(String($0))) }
      case .whitespace:
        return [" ", "\t", "\n", "\r"].map { self.format(terminal: Terminal(String($0))) }
      case .wildcard:
        throw WirthEBNFFormatterError.wildcard
      }
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
