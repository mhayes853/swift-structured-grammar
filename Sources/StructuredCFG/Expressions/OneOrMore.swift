public struct OneOrMore: Hashable, Sendable, ConvertibleToExpression {
  public let expression: Expression

  public init(_ expression: some ConvertibleToExpression) {
    self.expression = .oneOrMore(expression.expression)
  }

  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.init(content())
  }
}
