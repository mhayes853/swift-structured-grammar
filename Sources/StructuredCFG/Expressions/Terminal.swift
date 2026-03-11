public struct Terminal: Hashable, Sendable, ExpressibleByStringLiteral, ConvertibleToExpression {
  public let value: String

  public init(_ value: String) {
    self.value = value
  }

  public init(stringLiteral value: String) {
    self.init(value)
  }

  public var expression: Expression {
    .terminal(self)
  }
}
