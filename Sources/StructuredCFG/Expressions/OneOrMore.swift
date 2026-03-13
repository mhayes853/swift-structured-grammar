public struct OneOrMore: Hashable, Sendable, ExpressionComponent {
  public let expression: Expression

  public init(_ expression: some ExpressionComponent) {
    self.expression = .oneOrMore(expression.expression)
  }

  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.init(content())
  }
}
