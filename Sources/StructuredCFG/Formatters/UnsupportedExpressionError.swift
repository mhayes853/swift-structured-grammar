public struct UnsupportedExpressionError: Error, Hashable, Sendable {
  public let message: String

  public init(_ message: String) {
    self.message = message
  }

  public static let customExpression = UnsupportedExpressionError(
    "Custom expressions are not supported"
  )
}
