// MARK: - StatementFormatter

extension Grammar {
  /// A type that formats individual statements into a textual grammar notation.
  public protocol StatementFormatter: Sendable {
    /// Formats a single statement.
    ///
    /// - Parameter statement: The ``Grammar/Statement`` to format.
    /// - Returns: A textual representation of `statement`.
    func format(statement: Statement) throws -> String
  }
}

// MARK: - Formatting

extension Grammar {
  /// Formats the grammar by applying a ``StatementFormatter`` to each statement in order.
  ///
  /// - Parameter formatter: The ``StatementFormatter`` used to format each statement.
  /// - Returns: A newline-separated textual representation of the grammar.
  public func formatted(with formatter: some StatementFormatter) throws -> String {
    try self.statements
      .map { try formatter.format(statement: $0) }
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
  }
}
