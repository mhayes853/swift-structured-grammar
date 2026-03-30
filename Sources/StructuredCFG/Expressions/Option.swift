/// An expression component that matches an optional expression.
public struct OptionalExpression: Hashable, Sendable, Expression.Component {
  public let expression: Expression

  /// Creates an optional expression from an expression component.
  ///
  /// - Parameter expression: The expression to make optional.
  @inlinable
  public init(_ expression: some Expression.Component) {
    self.expression = .optional(expression.expression)
  }

  /// Creates an optional expression from a result-builder closure.
  ///
  /// - Parameter content: A builder that produces the optional expression.
  @inlinable
  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.expression = .optional(content())
  }
}
