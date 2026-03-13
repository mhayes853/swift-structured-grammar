public struct Union: Hashable, Sendable, LanguageComponent {
  public let language: Language

  public init(@UnionBuilder _ content: () -> [Language]) {
    self.language = .union(content())
  }
}
