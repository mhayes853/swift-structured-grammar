public struct Production: Hashable, Sendable {
  public let identifier: Identifier
  public let expression: Expression

  public init(
    _ identifier: Identifier,
    @ExpressionBuilder _ expression: () -> Expression
  ) {
    self.identifier = identifier
    self.expression = expression()
  }

  public init(
    _ identifier: Identifier,
    _ expression: some ConvertibleToExpression
  ) {
    self.identifier = identifier
    self.expression = expression.expression
  }
}
