public struct ZeroOrMore: Hashable, Sendable, ExpressionComponent {
  public let expression: Expression

  public init(_ expression: some ExpressionComponent) {
    self.expression = .zeroOrMore(expression.expression)
  }

  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.expression = .zeroOrMore(content())
  }
}
