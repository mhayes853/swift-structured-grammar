public struct EmptyExpression: Hashable, Sendable, ExpressionComponent {
  public init() {}

  public var expression: Expression {
    Expression.empty
  }
}
