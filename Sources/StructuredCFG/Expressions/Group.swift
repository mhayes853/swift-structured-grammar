/// An expression component that groups another expression to preserve precedence.
public struct GroupExpression: Hashable, Sendable, Expression.Component {
  public let expression: Expression

  /// Creates a grouped expression from an expression component.
  ///
  /// - Parameter expression: The expression to group.
  @inlinable
  public init(_ expression: some Expression.Component) {
    self.expression = .group(expression.expression)
  }

  /// Creates a grouped expression from a result-builder closure.
  ///
  /// - Parameter content: A builder that produces the grouped expression.
  @inlinable
  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.expression = .group(content())
  }
}
