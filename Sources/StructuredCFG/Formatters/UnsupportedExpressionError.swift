/// An error thrown when a formatter cannot represent a particular expression.
public struct UnsupportedExpressionError: Error, Hashable, Sendable {
  /// A human-readable error message.
  public let message: String

  /// Creates an unsupported-expression error.
  ///
  /// - Parameter message: A human-readable description of the failure.
  public init(_ message: String) {
    self.message = message
  }

  /// An error indicating that custom expressions are unsupported.
  public static let customExpression = UnsupportedExpressionError(
    "Custom expressions are not supported"
  )
}
