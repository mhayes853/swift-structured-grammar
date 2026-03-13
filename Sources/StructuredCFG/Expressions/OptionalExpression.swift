public struct OptionalExpression: Hashable, Sendable, ExpressionComponent {
  public let expression: Expression

  public init(_ expression: some ExpressionComponent) {
    self.expression = .optional(expression.expression)
  }

  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.expression = .optional(content())
  }
}
