extension Grammar {
  public struct BNFFormatter: Formatter {
    public init() {}

    public func format(rule: Rule) throws -> String {
      var builder = Builder(rootSymbol: rule.symbol)
      let alternatives = try builder.lower(expression: rule.expression.simplified)

      var lines = [String]()
      lines.append("\(self.format(symbol: rule.symbol)) ::= \(self.format(alternatives: alternatives))")
      lines.append(contentsOf: builder.helperLines)
      return lines.joined(separator: "\n")
    }

    private func format(symbol: Symbol) -> String {
      "<\(symbol.rawValue)>"
    }

    private func format(alternatives: [[Atom]]) -> String {
      alternatives
        .map { sequence in
          if sequence.isEmpty {
            self.quote("")
          } else {
            sequence.map { self.format(atom: $0) }.joined(separator: " ")
          }
        }
        .joined(separator: " | ")
    }

    private func format(atom: Atom) -> String {
      switch atom {
      case .symbol(let symbol):
        self.format(symbol: symbol)
      case .terminal(let terminal):
        self.format(terminal: terminal)
      case .optional(let alternatives):
        "[\(self.format(alternatives: alternatives))]"
      }
    }

    private func format(terminal: Terminal) -> String {
      let escaped = terminal.parts.reduce(into: "") { result, part in
        switch part {
        case .string(let string):
          result += self.escape(string)
        case .hex(let scalars):
          result += self.escape(String(String.UnicodeScalarView(scalars)))
        }
      }
      return self.quote(escaped, isEscaped: true)
    }

    private func quote(_ string: String, isEscaped: Bool = false) -> String {
      let body = isEscaped ? string : self.escape(string)
      return "\"" + body + "\""
    }

    private func escape(_ string: String) -> String {
      string.reduce(into: "") { result, character in
        switch character {
        case "\\":
          result += "\\\\"
        case "\"":
          result += "\\\""
        default:
          result.append(character)
        }
      }
    }

    private enum Atom: Hashable, Sendable {
      case symbol(Symbol)
      case terminal(Terminal)
      case optional([[Atom]])
    }

    private struct Builder {
      let rootSymbol: Symbol
      var helperCounter = 0
      var helperLines = [String]()

      mutating func lower(expression: Expression) throws -> [[Atom]] {
        switch expression {
        case .epsilon:
          return [[]]
        case .concat(let expressions):
          return try expressions.reduce(into: [[]]) { partialResult, expression in
            let next = try self.lower(expression: expression)
            partialResult = self.concatenate(partialResult, next)
          }
        case .choice(let expressions):
          return try expressions.flatMap { try self.lower(expression: $0) }
        case .optional(let expression):
          return [[.optional(try self.lower(expression: expression))]]
        case .repeat(let repeatExpression):
          return try self.lower(repeatExpression: repeatExpression)
        case .group(let expression):
          return try self.lower(expression: expression)
        case .characterGroup(let group):
          return try self.lower(characterGroup: group)
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

      private mutating func lower(repeatExpression: Repeat) throws -> [[Atom]] {
        let inner = try self.lower(expression: repeatExpression.innerExpression)

        switch (repeatExpression.min, repeatExpression.max) {
        case (nil, nil):
          throw UnsupportedExpressionError("Repeat ranges must have at least one bound")
        case (let min?, let max?) where min == max:
          return self.repeated(inner, count: min)
        case (let min?, nil):
          if min == 0 {
            let symbol = self.nextHelperSymbol()
            let recursiveAlternatives = [[]] + self.concatenate(inner, [[.symbol(symbol)]])
            self.helperLines.append(
              "<\(symbol.rawValue)> ::= \(BNFFormatter().format(alternatives: recursiveAlternatives))"
            )
            return [[.symbol(symbol)]]
          }

          let zeroOrMore = try self.lower(
            repeatExpression: Repeat(min: 0, max: nil, repeatExpression.innerExpression)
          )
          return self.concatenate(self.repeated(inner, count: min), zeroOrMore)
        case (nil, let max?):
          return self.lowerAtMost(inner: inner, max: max)
        case (let min?, let max?):
          let required = self.repeated(inner, count: min)
          let optionalTail = self.lowerAtMost(inner: inner, max: max - min)
          return self.concatenate(required, optionalTail)
        }
      }

      private mutating func lowerAtMost(inner: [[Atom]], max: Int) -> [[Atom]] {
        guard max > 0 else {
          return [[]]
        }

        let alternatives = (1...max).flatMap { self.repeated(inner, count: $0) }
        return [[.optional(alternatives)]]
      }

      private mutating func lower(characterGroup: CharacterGroup) throws -> [[Atom]] {
        if characterGroup.isNegated {
          throw UnsupportedExpressionError("Negated character groups are not supported")
        }

        return try characterGroup.members.flatMap { member in
          try self.lower(characterGroupMember: member)
        }
      }

      private func lower(characterGroupMember member: CharacterGroup.Member) throws -> [[Atom]] {
        switch member {
        case .character(let character):
          return [[.terminal(Terminal(character))]]
        case .range(let start, let end):
          guard let startValue = start.asciiValue, let endValue = end.asciiValue else {
            throw UnsupportedExpressionError("Non-ASCII character ranges are not supported")
          }
          return (startValue...endValue).map { value in
            [.terminal(Terminal(Character(UnicodeScalar(value))))]
          }
        case .escaped(let escape):
          return [[.terminal(Terminal(self.string(for: escape)))]]
        case .hex(let scalar):
          return [[.terminal(Terminal(Character(scalar)))]]
        case .hexRange(let start, let end):
          guard start.isASCII, end.isASCII else {
            throw UnsupportedExpressionError("Non-ASCII character ranges are not supported")
          }
          return (start.value...end.value).compactMap { value in
            Unicode.Scalar(value).map { [.terminal(Terminal(Character($0)))] }
          }
        }
      }

      private mutating func makeHelper(alternatives: [[Atom]]) -> Symbol {
        let symbol = self.nextHelperSymbol()
        self.helperLines.append("<\(symbol.rawValue)> ::= \(BNFFormatter().format(alternatives: alternatives))")
        return symbol
      }

      private mutating func nextHelperSymbol() -> Symbol {
        self.helperCounter += 1
        return Symbol("\(self.rootSymbol.rawValue)__bnf_\(self.helperCounter)")
      }

      private func repeated(_ alternatives: [[Atom]], count: Int) -> [[Atom]] {
        if count == 0 {
          return [[]]
        }

        return (0..<count).reduce([[]]) { partialResult, _ in
          self.concatenate(partialResult, alternatives)
        }
      }

      private func concatenate(_ lhs: [[Atom]], _ rhs: [[Atom]]) -> [[Atom]] {
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
    }
  }
}

extension Grammar.Formatter where Self == Grammar.BNFFormatter {
  public static var bnf: Grammar.BNFFormatter {
    Grammar.BNFFormatter()
  }
}
