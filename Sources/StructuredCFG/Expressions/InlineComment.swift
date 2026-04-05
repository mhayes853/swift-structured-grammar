/// An expression component that attaches a formatter-emitted inline comment to an expression.
public struct InlineComment: Hashable, Sendable, Expression.Component {
  public enum Position: Hashable, Sendable {
    case leading
    case trailing
  }

  /// The raw inline comment text.
  public let text: String

  /// The expression the comment is attached to.
  public let baseExpression: Expression

  /// Whether the comment is rendered before or after the base expression.
  public let position: Position

  @inlinable
  public var expression: Expression {
    .inlineComment(self)
  }

  /// Creates an inline comment attached to an expression component.
  ///
  /// - Parameters:
  ///   - text: The raw inline comment text.
  ///   - position: Whether the comment appears before or after the expression.
  ///   - expression: The expression to annotate.
  @inlinable
  public init(
    _ text: String,
    position: Position = .trailing,
    _ expression: some Expression.Component
  ) {
    self.text = text
    self.baseExpression = expression.expression
    self.position = position
  }

  /// Creates an inline comment attached to a builder-produced expression.
  ///
  /// - Parameters:
  ///   - text: The raw inline comment text.
  ///   - position: Whether the comment appears before or after the expression.
  ///   - content: A builder that produces the annotated expression.
  @inlinable
  public init(
    _ text: String,
    position: Position = .trailing,
    @ExpressionBuilder _ content: () -> Expression
  ) {
    self.init(text, position: position, content())
  }
}

extension Expression.Component {
  /// Attaches a formatter-emitted inline comment to this expression component.
  ///
  /// - Parameters:
  ///   - text: The raw inline comment text.
  ///   - position: Whether the comment appears before or after the expression.
  /// - Returns: An inline-comment expression wrapping this component.
  @inlinable
  public func comment(
    _ text: String,
    position: InlineComment.Position = .trailing
  ) -> InlineComment {
    InlineComment(text, position: position, self)
  }
}
