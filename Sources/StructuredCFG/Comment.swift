/// A top-level comment emitted by grammar formatters.
public struct Comment: Hashable, Sendable {
  /// The raw comment text.
  public let text: String

  /// Creates a comment from raw text.
  ///
  /// - Parameter text: The raw comment text.
  public init(_ text: String) {
    self.text = text
  }
}
