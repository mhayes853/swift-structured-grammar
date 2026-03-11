public struct Production: Hashable, Sendable {
  public let symbol: Symbol
  public let expression: Expression

  public init(
    _ symbol: Symbol,
    @ExpressionBuilder _ expression: () -> Expression
  ) {
    self.symbol = symbol
    self.expression = expression()
  }

  public init(
    _ symbol: Symbol,
    _ expression: some ConvertibleToExpression
  ) {
    self.symbol = symbol
    self.expression = expression.expression
  }
}
