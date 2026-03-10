public struct ZeroOrMore: Hashable, Sendable, ConvertibleToExpression {
  public let expression: Expression

  public init(_ expression: some ConvertibleToExpression) {
    self.expression = .zeroOrMore(expression.expression)
  }

  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.expression = .zeroOrMore(content())
  }
}
