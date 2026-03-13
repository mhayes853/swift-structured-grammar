extension Grammar {
  public protocol Formatter: Sendable {
    func format(production: Production) -> String
  }
}
