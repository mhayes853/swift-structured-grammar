public struct GroupExpression: Hashable, Sendable, ExpressionComponent {
  public let expression: Expression

  @inlinable
  public init(_ expression: some ExpressionComponent) {
    self.expression = .group(expression.expression)
  }

  @inlinable
  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.expression = .group(content())
  }
}
