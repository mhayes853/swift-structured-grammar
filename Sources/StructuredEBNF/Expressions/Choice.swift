public struct Choice: Hashable, Sendable, ConvertibleToExpression {
  public let expression: Expression

  public init(_ expression: some ConvertibleToExpression) {
    self.expression = .choice([expression.expression])
  }
}
