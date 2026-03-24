/// A reusable component that can be converted into an ``Expression``.
public protocol ExpressionComponent {
  /// The expression represented by this component.
  @ExpressionBuilder
  var expression: Expression { get }
}
