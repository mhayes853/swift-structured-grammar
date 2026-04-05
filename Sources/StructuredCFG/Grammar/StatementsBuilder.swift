/// A result builder for constructing arrays of top-level grammar statements.
@resultBuilder
public enum StatementsBuilder {
  /// Lifts a single statement into builder output.
  ///
  /// - Parameter statement: The statement to include.
  /// - Returns: An array containing `statement`.
  @inlinable
  public static func buildExpression(_ statement: Grammar.Statement) -> [Grammar.Statement] {
    [statement]
  }

  @inlinable
  public static func buildExpression(_ component: some Grammar.Component) -> [Grammar.Statement] {
    Array(component.statements)
  }

  @inlinable
  public static func buildExpression(_ statements: some Sequence<Grammar.Statement>) -> [Grammar.Statement] {
    Array(statements)
  }

  @inlinable
  public static func buildBlock(_ components: [Grammar.Statement]...) -> [Grammar.Statement] {
    components.flatMap { $0 }
  }

  @inlinable
  public static func buildOptional(_ component: [Grammar.Statement]?) -> [Grammar.Statement] {
    component ?? [Grammar.Statement]()
  }

  @inlinable
  public static func buildEither(first component: [Grammar.Statement]) -> [Grammar.Statement] {
    component
  }

  @inlinable
  public static func buildEither(second component: [Grammar.Statement]) -> [Grammar.Statement] {
    component
  }

  @inlinable
  public static func buildArray(_ components: [[Grammar.Statement]]) -> [Grammar.Statement] {
    components.flatMap { $0 }
  }
}
