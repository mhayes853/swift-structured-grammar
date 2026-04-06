/// An expression component that matches zero or more repetitions of an expression.
public struct ZeroOrMore: Hashable, Sendable, Expression.Component {
  /// The expression being repeated.
  public let baseExpression: Expression

  /// Creates a zero-or-more repetition from an expression component.
  ///
  /// - Parameter expression: The expression to repeat.
  @inlinable
  public init(_ expression: some Expression.Component) {
    self.baseExpression = expression.expression
  }

  /// Creates a zero-or-more repetition from a result-builder closure.
  ///
  /// - Parameter content: A builder that produces the repeated expression.
  @inlinable
  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.init(content())
  }

  /// The repeated expression as an ``Expression``.
  @inlinable
  public var expression: Expression {
    Repeat(min: 0, max: nil, self.baseExpression).expression
  }
}
