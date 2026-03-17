public struct Ref: Hashable, Sendable, ExpressionComponent {
  public let symbol: Symbol

  @inlinable
  public init(_ symbol: Symbol) {
    self.symbol = symbol
  }

  @inlinable
  public var expression: Expression {
    .ref(self)
  }
}
