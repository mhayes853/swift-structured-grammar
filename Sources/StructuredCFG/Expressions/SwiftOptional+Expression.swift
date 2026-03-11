extension Optional: ConvertibleToExpression where Wrapped: ConvertibleToExpression {
  public var expression: Expression {
    guard let wrapped = self else { return .empty }
    return wrapped.expression
  }
}
