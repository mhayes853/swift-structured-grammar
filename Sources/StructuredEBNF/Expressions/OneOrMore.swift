public struct OneOrMore: Hashable, Sendable, ConvertibleToExpression {
  public let expression: Expression

  public init(_ expression: some ConvertibleToExpression) {
    self.expression = .concat([expression.expression, .zeroOrMore(expression.expression)])
  }
}
