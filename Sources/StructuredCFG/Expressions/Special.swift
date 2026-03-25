/// An expression component that stores a formatter-specific special sequence.
public struct Special: Hashable, Sendable, Expression.Component {
  /// The raw special-sequence value.
  public let value: String

  /// Creates a special sequence expression.
  ///
  /// - Parameter value: The special-sequence payload.
  @inlinable
  public init(_ value: String) {
    self.value = value
  }

  @inlinable
  public var expression: Expression {
    .special(self)
  }
}
