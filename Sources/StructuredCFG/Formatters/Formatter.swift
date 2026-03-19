// MARK: - RuleFormatter

extension Grammar {
  public protocol RuleFormatter: Sendable {
    func format(rule: Rule) throws -> String
  }
}

// MARK: - Formatting

extension Grammar {
  public func formatted(with formatter: some RuleFormatter) throws -> String {
    try self.rules
      .map { try formatter.format(rule: $0) }
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
  }
}
