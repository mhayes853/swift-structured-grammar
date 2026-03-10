public struct OptionalExpression: Hashable, Sendable, ConvertibleToExpression {
  public let expression: Expression

  public init(_ expression: some ConvertibleToExpression) {
    self.expression = .optional(expression.expression)
  }

  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.expression = .optional(content())
  }
}
