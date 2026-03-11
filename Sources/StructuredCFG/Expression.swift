public indirect enum Expression: Hashable, Sendable, ConvertibleToExpression {
  case empty
  case concat([Expression])
  case choice([Expression])
  case optional(Expression)
  case zeroOrMore(Expression)
  case group(Expression)
  case ref(Symbol)
  case special(Special)
  case terminal(Terminal)

  public var expression: Self {
    self
  }
}
