extension Grammar {
  public enum Quoting: Sendable {
    case single
    case double
  }

  public struct W3CEBNFFormatter: Formatter {
    public var quoting: Quoting = .double

    public init(quoting: Quoting = .double) {
      self.quoting = quoting
    }

    public func format(rule: Rule) throws -> String {
      let expression = rule.expression.simplified
      if expression == .empty {
        throw UnsupportedExpressionError("Empty expressions are not supported")
      }
      if case .custom = expression {
        throw UnsupportedExpressionError.customExpression
      }
      let formatted = self.format(expression: expression)
      if formatted.isEmpty {
        return ""
      }
      return "\(rule.symbol.rawValue) ::= \(formatted)"
    }

    private func format(expression: Expression) -> String {
      switch expression {
      case .empty:
        return ""
      case .concat(let expressions):
        return
          expressions
          .map { expression in
            if case .choice = expression {
              "(\(self.format(expression: expression)))"
            } else {
              self.format(expression: expression)
            }
          }
          .joined(separator: " ")
      case .choice(let expressions):
        return expressions.map { self.format(expression: $0) }.joined(separator: " | ")
      case .optional(let expression):
        return self.formatPrimary(expression: expression) + "?"
      case .`repeat`(let repeatExpr):
        if repeatExpr.isZeroOrMore {
          return self.formatPrimary(expression: repeatExpr.innerExpression) + "*"
        }
        if repeatExpr.isOneOrMore {
          return self.formatPrimary(expression: repeatExpr.innerExpression) + "+"
        }
        let innerExpression = repeatExpr.innerExpression
        switch (repeatExpr.min, repeatExpr.max) {
        case (let n?, nil):
          if n == 0 {
            return self.formatPrimary(expression: innerExpression) + "*"
          } else {
            let required = Expression.concat(Array(repeating: innerExpression, count: n))
            let expanded: Expression = .concat([
              required, Repeat(min: 0, max: nil, innerExpression).expression
            ])
            return self.format(expression: expanded.simplified)
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
            return self.format(expression: expanded.simplified)
          }
        case (let m?, let n?) where m == n:
          if m == 0 {
            return ""
          }
          let expanded = Expression.concat(Array(repeating: innerExpression, count: m))
          return self.format(expression: expanded.simplified)
        case (let m?, let n?):
          let required = Expression.concat(Array(repeating: innerExpression, count: m))
          let additionalMax = n - m
          var additionalChoices: [Expression] = [.empty]
          for i in 1...additionalMax {
            additionalChoices.append(Expression.concat(Array(repeating: innerExpression, count: i)))
          }
          let optionalAdditional = Expression.optional(Expression.choice(additionalChoices))
          let expanded: Expression = .concat([required, optionalAdditional])
          return self.format(expression: expanded.simplified)
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
      case .custom:
        return ""
      }
    }

    private func formatPrimary(expression: Expression) -> String {
      if expression.isPrimary {
        self.format(expression: expression)
      } else {
        "(\(self.format(expression: expression)))"
      }
    }

    private func format(terminal: Terminal) -> String {
      let escaped: String
      switch self.quoting {
      case .double:
        escaped = terminal.value.reduce(into: "") { result, character in
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
        escaped = terminal.value.reduce(into: "") { result, character in
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

    private func format(characterGroup: CharacterGroup) -> String {
      if let shorthand = self.shorthand(for: characterGroup) {
        return shorthand
      }

      var result = characterGroup.isNegated ? "[^" : "["

      var memberIndex = 0
      while memberIndex < characterGroup.members.count {
        if let shorthand = self.shorthand(
          in: characterGroup.members,
          startingAt: memberIndex,
          isNegated: characterGroup.isNegated
        ) {
          result += shorthand.value
          memberIndex += shorthand.memberCount
          continue
        }

        let member = characterGroup.members[memberIndex]
        switch member {
        case .character(let char):
          result.append(char)
        case .range(let start, let end):
          result.append(start)
          result.append("-")
          result.append(end)
        case .escaped(let escape):
          result += self.format(escape: escape)
        case .hex(let codePoint):
          result += "#x"
          result += String(codePoint, radix: 16)
        case .hexRange(let start, let end):
          result += "#x"
          result += String(start, radix: 16)
          result += "-#x"
          result += String(end, radix: 16)
        }
        memberIndex += 1
      }

      result.append("]")
      return result
    }

    private func shorthand(for characterGroup: CharacterGroup) -> String? {
      if characterGroup.isDigit {
        return "[\\d]"
      }
      if characterGroup.isWord {
        return "[\\w]"
      }
      if characterGroup.isWhitespace {
        return "[\\s]"
      }
      if characterGroup.isNonDigit {
        return "[\\D]"
      }
      if characterGroup.isNonWord {
        return "[\\W]"
      }
      if characterGroup.isNonWhitespace {
        return "[\\S]"
      }
      return nil
    }

    private func shorthand(
      in members: [CharacterGroup.Member],
      startingAt startIndex: Int,
      isNegated: Bool
    ) -> (value: String, memberCount: Int)? {
      let remainingMembers = Array(members[startIndex...])

      if !isNegated, remainingMembers.starts(with: Self.wordMembers) {
        return (value: "\\w", memberCount: Self.wordMembers.count)
      }
      if !isNegated, remainingMembers.starts(with: Self.whitespaceMembers) {
        return (value: "\\s", memberCount: Self.whitespaceMembers.count)
      }
      if remainingMembers.starts(with: Self.digitMembers) {
        return (value: isNegated ? "\\D" : "\\d", memberCount: Self.digitMembers.count)
      }
      return nil
    }

    private func format(escape: CharacterGroup.EscapeSequence) -> String {
      switch escape {
      case .backslash:
        "\\\\"
      case .pipe:
        "\\|"
      case .period:
        "\\."
      case .hyphen:
        "\\-"
      case .caret:
        "\\^"
      case .question:
        "\\?"
      case .asterisk:
        "\\*"
      case .plus:
        "\\+"
      case .leftBrace:
        "\\{"
      case .rightBrace:
        "\\}"
      case .leftParen:
        "\\("
      case .rightParen:
        "\\)"
      case .leftBracket:
        "\\["
      case .rightBracket:
        "\\]"
      case .newline:
        "\\n"
      case .carriageReturn:
        "\\r"
      case .tab:
        "\\t"
      }
    }

    private static let digitMembers: [CharacterGroup.Member] = [.range("0", "9")]

    private static let wordMembers: [CharacterGroup.Member] = [
      .range("a", "z"),
      .range("A", "Z"),
      .range("0", "9"),
      .character("_")
    ]

    private static let whitespaceMembers: [CharacterGroup.Member] = [
      .character(" "),
      .escaped(.tab),
      .escaped(.newline),
      .escaped(.carriageReturn)
    ]
  }
}

extension Grammar.Formatter where Self == Grammar.W3CEBNFFormatter {
  public static var w3cEbnf: Grammar.W3CEBNFFormatter {
    Grammar.W3CEBNFFormatter()
  }

  public static func w3cEbnf(quoting: Grammar.Quoting = .double) -> Grammar.W3CEBNFFormatter {
    Grammar.W3CEBNFFormatter(quoting: quoting)
  }
}
