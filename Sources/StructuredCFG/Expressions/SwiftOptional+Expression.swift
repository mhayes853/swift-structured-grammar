extension Optional: ConvertibleToExpression where Wrapped: ConvertibleToExpression {
  public var expression: Expression {
    guard let wrapped = self else { return Expression.empty }
    return wrapped.expression
  }
}
