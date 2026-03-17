public struct ConcatenateExpressions: Hashable, Sendable, ExpressionComponent {
  public let expression: Expression

  @inlinable
  public init(_ expression: some ExpressionComponent) {
    self.expression = .concat([expression.expression])
  }

  @inlinable
  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.expression = content()
  }
}
