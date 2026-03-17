extension Optional: ExpressionComponent where Wrapped: ExpressionComponent {
  @inlinable
  public var expression: Expression {
    guard let wrapped = self else { return Expression.empty }
    return wrapped.expression
  }
}
