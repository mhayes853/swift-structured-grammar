/// An expression component that matches one of several alternatives.
public struct Choice: Hashable, Sendable, Expression.Component {
  public let expression: Expression

  /// Creates a choice expression from a result-builder closure.
  ///
  /// - Parameter content: A builder that produces the choice alternatives.
  @inlinable
  public init(@ChoiceBuilder _ content: () -> [Expression]) {
    self.expression = .choice(content())
  }
}
