/// An expression component that concatenates expressions in sequence.
public struct ConcatenateExpressions: Hashable, Sendable, ExpressionComponent {
  public let expression: Expression

  /// Creates a concatenation from an expression component.
  ///
  /// - Parameter expression: The expression to concatenate.
  @inlinable
  public init(_ expression: some ExpressionComponent) {
    self.expression = .concat([expression.expression])
  }

  /// Creates a concatenation from a result-builder closure.
  ///
  /// - Parameter content: A builder that produces the concatenated expression.
  @inlinable
  public init(@ExpressionBuilder _ content: () -> Expression) {
    self.expression = content()
  }
}
