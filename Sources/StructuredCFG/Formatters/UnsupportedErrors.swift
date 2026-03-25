// MARK: - UnsupportedExpressionError

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

// MARK: - UnsupportedStatementError

/// An error thrown when a formatter cannot represent a particular top-level statement.
public struct UnsupportedStatementError: Error, Hashable, Sendable {
  /// A human-readable error message.
  public let message: String

  /// Creates an unsupported-statement error.
  public init(_ message: String) {
    self.message = message
  }

  /// An error indicating that custom statements are unsupported.
  public static let customStatement = UnsupportedStatementError(
    "Custom statements are not supported"
  )
}
