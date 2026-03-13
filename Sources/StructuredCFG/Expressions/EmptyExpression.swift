public struct EmptyExpression: Hashable, Sendable, ConvertibleToExpression {
  public init() {}

  public var expression: Expression {
    Expression.empty
  }
}
