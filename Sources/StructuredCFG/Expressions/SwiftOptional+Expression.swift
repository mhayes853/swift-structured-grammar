extension Optional: ExpressionComponent where Wrapped: ExpressionComponent {
  @inlinable
  public var expression: Expression {
    self.map { $0.expression } ?? .epsilon
  }
}
