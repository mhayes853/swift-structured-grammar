public struct Terminal: Hashable, Sendable, ExpressibleByStringLiteral, ExpressionComponent {
  public let value: String

  public init(_ value: String) {
    self.value = value
  }

  public init(_ value: Character) {
    self.init(String(value))
  }

  public init(stringLiteral value: String) {
    self.init(value)
  }

  public var expression: Expression {
    Expression.terminal(self)
  }
}
