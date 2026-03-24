// MARK: - Expression

/// A grammar expression that describes how a rule can match input.
///
/// This enum is maked as `@nonexhaustive`, which means that new cases may be added in future
/// releases.
///
/// You can use the `custom` case to support expressions for custom grammar formats.
@nonexhaustive
public indirect enum Expression: Sendable, ExpressionComponent {
  /// Matches the empty string.
  case epsilon

  /// Matches a sequence of expressions in order.
  case concat([Expression])

  /// Matches any one of several alternatives.
  case choice([Expression])

  /// Matches an optional expression.
  case optional(Expression)

  /// Matches a repeated expression.
  case `repeat`(Repeat)

  /// Groups an expression to preserve precedence.
  case group(Expression)

  /// Matches a character class.
  case characterGroup(CharacterGroup)

  /// References another rule by symbol.
  case ref(Ref)

  /// Matches a formatter-specific special sequence.
  case special(Special)

  /// Matches a literal terminal value.
  case terminal(Terminal)

  /// Stores a custom formatter-defined payload.
  case custom(any Hashable & Sendable)

  public var expression: Self {
    self
  }
}

// MARK: - Equatable

extension Expression: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.epsilon, .epsilon): true
    case (.concat(let l1), .concat(let l2)): l1 == l2
    case (.choice(let l1), .choice(let l2)): l1 == l2
    case (.optional(let l1), .optional(let r1)): l1 == r1
    case (.repeat(let l1), .repeat(let r1)): l1 == r1
    case (.group(let l1), .group(let r1)): l1 == r1
    case (.characterGroup(let l1), .characterGroup(let r1)): l1 == r1
    case (.ref(let l1), .ref(let r1)): l1 == r1
    case (.special(let l1), .special(let r1)): l1 == r1
    case (.terminal(let l1), .terminal(let r1)): l1 == r1
    case (.custom(let l1), .custom(let r1)): equals(l1, r1)
    default: false
    }
  }
}

// MARK: - Hashable

extension Expression: Hashable {
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .epsilon:
      hasher.combine(0)
    case .concat(let expressions):
      hasher.combine(1)
      hasher.combine(expressions)
    case .choice(let expressions):
      hasher.combine(2)
      hasher.combine(expressions)
    case .optional(let expression):
      hasher.combine(3)
      hasher.combine(expression)
    case .repeat(let repeatExpr):
      hasher.combine(4)
      hasher.combine(repeatExpr)
    case .group(let expression):
      hasher.combine(5)
      hasher.combine(expression)
    case .characterGroup(let characterGroup):
      hasher.combine(6)
      hasher.combine(characterGroup)
    case .ref(let ref):
      hasher.combine(7)
      hasher.combine(ref)
    case .special(let special):
      hasher.combine(8)
      hasher.combine(special)
    case .terminal(let terminal):
      hasher.combine(9)
      hasher.combine(terminal)
    case .custom(let value):
      hasher.combine(10)
      value.hash(into: &hasher)
    }
  }
}
