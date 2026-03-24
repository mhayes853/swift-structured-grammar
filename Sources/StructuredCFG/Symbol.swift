/// A non-terminal symbol used to identify a grammar rule.
public struct Symbol: Hashable, Sendable, RawRepresentable, ExpressibleByStringLiteral {
  /// The default starting symbol used by grammars in this library.
  public static let root = Symbol(rawValue: "root")

  /// The underlying symbol name.
  public let rawValue: String

  /// Creates a symbol from a raw string value.
  ///
  /// - Parameter rawValue: The symbol name.
  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  /// Creates a symbol from a raw string value.
  ///
  /// - Parameter rawValue: The symbol name.
  public init(rawValue: String) {
    self.init(rawValue)
  }

  /// Creates a symbol from a string literal.
  ///
  /// - Parameter value: The symbol name.
  public init(stringLiteral value: String) {
    self.rawValue = value
  }
}
