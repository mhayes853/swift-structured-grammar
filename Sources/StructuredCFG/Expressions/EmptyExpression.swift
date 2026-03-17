public struct EmptyExpression: Hashable, Sendable, ExpressionComponent {
  @inlinable
  public init() {}

  @inlinable
  public var expression: Expression {
    Expression.empty
  }
}
