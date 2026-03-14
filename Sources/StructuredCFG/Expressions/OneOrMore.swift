public struct OneOrMore: Hashable, Sendable, ExpressionComponent {
  public let expression: Expression

  public init(_ expression: some ExpressionComponent) {
    self.expression = Repeat(min: 1, max: nil, expression).expression
  }

  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.init(content())
  }
}
