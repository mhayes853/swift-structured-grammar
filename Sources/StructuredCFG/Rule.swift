/// A production rule that maps a symbol to an expression.
public struct Rule: Hashable, Sendable {
  /// The symbol produced by this rule.
  public let symbol: Symbol

  /// The expression associated with ``symbol``.
  public let expression: Expression

  /// Creates a rule from a symbol and expression builder.
  ///
  /// - Parameters:
  ///   - symbol: The symbol defined by the rule.
  ///   - expression: A builder that produces the rule's expression.
  public init(
    _ symbol: Symbol,
    @ExpressionBuilder _ expression: () -> Expression
  ) {
    self.symbol = symbol
    self.expression = expression()
  }

  /// Creates a rule from a symbol and expression component.
  ///
  /// - Parameters:
  ///   - symbol: The symbol defined by the rule.
  ///   - expression: The expression component to associate with `symbol`.
  public init(
    _ symbol: Symbol,
    _ expression: some Expression.Component
  ) {
    self.init(symbol) { expression.expression }
  }
}
