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

  public var character: Character? {
    guard self.value.count == 1 else { return nil }
    return self.value.first
  }
}
