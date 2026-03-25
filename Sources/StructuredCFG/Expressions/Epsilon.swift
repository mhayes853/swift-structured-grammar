/// An expression component that matches the empty string.
public struct Epsilon: Hashable, Sendable, Expression.Component {
  public let expression = Expression.epsilon

  /// Creates an epsilon expression.
  @inlinable
  public init() {}
}
