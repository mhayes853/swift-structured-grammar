extension Optional: ExpressionComponent where Wrapped: ExpressionComponent {
  public var expression: Expression {
    guard let wrapped = self else { return Expression.empty }
    return wrapped.expression
  }
}
