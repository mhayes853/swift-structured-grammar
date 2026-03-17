public struct OptionalExpression: Hashable, Sendable, ExpressionComponent {
  public let expression: Expression

  @inlinable
  public init(_ expression: some ExpressionComponent) {
    self.expression = .optional(expression.expression)
  }

  @inlinable
  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.expression = .optional(content())
  }
}
