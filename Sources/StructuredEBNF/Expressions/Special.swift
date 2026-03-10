public struct Special: Hashable, Sendable, ExpressibleByStringLiteral {
  public let value: String

  public init(_ value: String) {
    self.value = value
  }

  public init(stringLiteral value: String) {
    self.init(value)
  }
}
