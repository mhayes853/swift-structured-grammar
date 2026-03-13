public struct Ref: Hashable, Sendable, ExpressionComponent {
  public let symbol: Symbol

  public init(_ symbol: Symbol) {
    self.symbol = symbol
  }

  public var expression: Expression {
    Expression.ref(self.symbol)
  }
}
