// MARK: - Expression

public indirect enum Expression: Sendable, ExpressionComponent {
  case empty
  case concat([Expression])
  case choice([Expression])
  case optional(Expression)
  case `repeat`(Repeat)
  case group(Expression)
  case characterGroup(CharacterGroup)
  case ref(Symbol)
  case terminal(Terminal)
  case custom(any Hashable & Sendable)

  public var expression: Self {
    self
  }
}

// MARK: - Equatable

extension Expression: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.empty, .empty): true
    case (.concat(let l1), .concat(let l2)): l1 == l2
    case (.choice(let l1), .choice(let l2)): l1 == l2
    case (.optional(let l1), .optional(let r1)): l1 == r1
    case (.repeat(let l1), .repeat(let r1)): l1 == r1
    case (.group(let l1), .group(let r1)): l1 == r1
    case (.characterGroup(let l1), .characterGroup(let r1)): l1 == r1
    case (.ref(let l1), .ref(let r1)): l1 == r1
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
    case .empty:
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
    case .ref(let symbol):
      hasher.combine(7)
      hasher.combine(symbol)
    case .terminal(let terminal):
      hasher.combine(8)
      hasher.combine(terminal)
    case .custom(let value):
      hasher.combine(9)
      value.hash(into: &hasher)
    }
  }
}
