public struct OneOrMore: Hashable, Sendable, ExpressionComponent {
  public let innerExpression: Expression

  @inlinable
  public init(_ expression: some ExpressionComponent) {
    self.innerExpression = expression.expression
  }

  @inlinable
  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.init(content())
  }

  @inlinable
  public var expression: Expression {
    Repeat(min: 1, max: nil, self.innerExpression).expression
  }
}
