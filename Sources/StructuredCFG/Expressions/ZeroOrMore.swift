public struct ZeroOrMore: Hashable, Sendable, ExpressionComponent {
  public let expression: Expression

  public init(_ expression: some ExpressionComponent) {
    self.expression = Repeat(min: 0, max: nil, expression).expression
  }

  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.expression = Repeat(min: 0, max: nil, content()).expression
  }
}
