// MARK: - Component

extension Grammar {
  /// A reusable component that contributes one or more top-level grammar statements.
  public protocol Component {
    associatedtype Statements: Sequence<Statement>

    /// The statements represented by this component.
    var statements: Statements { get }
  }
}

// MARK: - Base Conformances

extension Rule: Grammar.Component {
  public var statements: CollectionOfOne<Grammar.Statement> {
    CollectionOfOne(.rule(self))
  }
}

extension Comment: Grammar.Component {
  public var statements: CollectionOfOne<Grammar.Statement> {
    CollectionOfOne(.comment(self))
  }
}
