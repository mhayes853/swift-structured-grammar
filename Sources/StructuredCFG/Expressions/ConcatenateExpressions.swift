public struct ConcatenateExpressions: Hashable, Sendable, ExpressionComponent {
  public let expression: Expression

  public init(_ expression: some ExpressionComponent) {
    self.expression = .concat([expression.expression])
  }

  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.expression = content()
  }
}
