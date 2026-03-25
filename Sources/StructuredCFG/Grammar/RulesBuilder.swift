/// A result builder for constructing arrays of top-level grammar statements.
@resultBuilder
public enum StatementsBuilder {
  /// Lifts a single statement into builder output.
  ///
  /// - Parameter statement: The statement to include.
  /// - Returns: An array containing `statement`.
  public static func buildExpression(_ statement: Grammar.Statement) -> [Grammar.Statement] {
    [statement]
  }

  /// Lifts a component's statements into builder output.
  ///
  /// - Parameter component: The component whose statements should be included.
  /// - Returns: The statements produced by `component`.
  public static func buildExpression(_ component: some Grammar.Component) -> [Grammar.Statement] {
    Array(component.statements)
  }

  /// Lifts a sequence of statements into builder output.
  ///
  /// - Parameter statements: The statements to include.
  /// - Returns: The collected statements.
  public static func buildExpression(_ statements: some Sequence<Grammar.Statement>) -> [Grammar.Statement] {
    Array(statements)
  }

  /// Combines statement fragments from a builder block.
  ///
  /// - Parameter components: The statement fragments to combine.
  /// - Returns: A flattened array containing all built statements.
  public static func buildBlock(_ components: [Grammar.Statement]...) -> [Grammar.Statement] {
    components.flatMap { $0 }
  }

  /// Lifts an optional statement fragment into builder output.
  ///
  /// - Parameter component: The optional statement fragment.
  /// - Returns: `component` when present, otherwise an empty array.
  public static func buildOptional(_ component: [Grammar.Statement]?) -> [Grammar.Statement] {
    component ?? [Grammar.Statement]()
  }

  /// Selects the first conditional builder branch.
  ///
  /// - Parameter component: The chosen statement fragment.
  /// - Returns: `component` unchanged.
  public static func buildEither(first component: [Grammar.Statement]) -> [Grammar.Statement] {
    component
  }

  /// Selects the second conditional builder branch.
  ///
  /// - Parameter component: The chosen statement fragment.
  /// - Returns: `component` unchanged.
  public static func buildEither(second component: [Grammar.Statement]) -> [Grammar.Statement] {
    component
  }

  /// Flattens repeated statement fragments from a loop.
  ///
  /// - Parameter components: The repeated statement fragments.
  /// - Returns: A flattened array containing all built statements.
  public static func buildArray(_ components: [[Grammar.Statement]]) -> [Grammar.Statement] {
    components.flatMap { $0 }
  }
}
