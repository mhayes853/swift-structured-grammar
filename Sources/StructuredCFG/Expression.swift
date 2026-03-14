public indirect enum Expression: Hashable, Sendable, ExpressionComponent {
  case empty
  case concat([Expression])
  case choice([Expression])
  case optional(Expression)
  case `repeat`(Repeat)
  case group(Expression)
  case characterGroup(CharacterGroup)
  case ref(Symbol)
  case terminal(Terminal)

  public var expression: Self {
    self
  }
}
