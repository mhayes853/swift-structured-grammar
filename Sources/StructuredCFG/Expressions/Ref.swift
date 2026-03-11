public struct Ref: Hashable, Sendable, ConvertibleToExpression {
  public let symbol: Symbol

  public init(_ symbol: Symbol) {
    self.symbol = symbol
  }

  public var expression: Expression {
    .ref(self.symbol)
  }
}
