public struct Special: Hashable, Sendable, ExpressionComponent {
  public let value: String

  public init(_ value: String) {
    self.value = value
  }

  public var expression: Expression {
    .special(self)
  }
}
