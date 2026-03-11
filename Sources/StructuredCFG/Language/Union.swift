public struct Union: Hashable, Sendable, ConvertibleToLanguage {
  public let language: Language

  public init(@UnionBuilder _ content: () -> [Language]) {
    self.language = Language.union(content())
  }
}
