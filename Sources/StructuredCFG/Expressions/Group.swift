public struct Group: Hashable, Sendable, ExpressionComponent {
  public let expression: Expression

  public init(_ expression: some ExpressionComponent) {
    self.expression = .group(expression.expression)
  }

  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.expression = .group(content())
  }
}
