/// An expression component that matches the empty string.
public struct Epsilon: Hashable, Sendable, ExpressionComponent {
  public let expression = Expression.epsilon

  /// Creates an epsilon expression.
  @inlinable
  public init() {}
}
