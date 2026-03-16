extension Grammar {
  public protocol Formatter: Sendable {
    func format(rule: Rule) throws -> String
  }
}
