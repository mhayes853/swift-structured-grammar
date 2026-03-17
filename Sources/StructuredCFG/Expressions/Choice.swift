public struct Choice: Hashable, Sendable, ExpressionComponent {
  public let expression: Expression

  @inlinable
  public init(@ChoiceBuilder _ content: () -> [Expression]) {
    self.expression = .choice(content())
  }
}
