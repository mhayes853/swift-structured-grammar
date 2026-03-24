// MARK: - RuleFormatter

extension Grammar {
  /// A type that formats individual rules into a textual grammar notation.
  public protocol RuleFormatter: Sendable {
    /// Formats a single rule.
    ///
    /// - Parameter rule: The ``Rule`` to format.
    /// - Returns: A textual representation of `rule`.
    func format(rule: Rule) throws -> String
  }
}

// MARK: - Formatting

extension Grammar {
  /// Formats the grammar by applying a ``RuleFormatter`` to each rule in order.
  ///
  /// - Parameter formatter: The ``RuleFormatter`` used to format each rule.
  /// - Returns: A newline-separated textual representation of the grammar.
  public func formatted(with formatter: some RuleFormatter) throws -> String {
    try self.rules
      .map { try formatter.format(rule: $0) }
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
  }
}
