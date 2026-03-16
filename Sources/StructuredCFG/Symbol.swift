public struct Symbol: Hashable, Sendable, RawRepresentable, ExpressibleByStringLiteral {
  public static let root = Symbol(rawValue: "root")

  public let rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    self.rawValue = value
  }
}
