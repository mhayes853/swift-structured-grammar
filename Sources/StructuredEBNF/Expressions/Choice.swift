public struct Choice: Hashable, Sendable, ConvertibleToExpression {
  public let expression: Expression

  public init(singleAlternative expression: some ConvertibleToExpression) {
    self.expression = .choice([expression.expression])
  }

  public init(@ChoiceBuilder _ content: () -> [Expression]) {
    self.expression = .choice(content())
  }
}
