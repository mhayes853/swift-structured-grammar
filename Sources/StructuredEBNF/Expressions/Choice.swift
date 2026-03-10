public struct Choice: Hashable, Sendable, ConvertibleToExpression {
  public let expression: Expression

  public init(@ChoiceBuilder _ content: () -> [Expression]) {
    self.expression = .choice(content())
  }
}
