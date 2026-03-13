public struct KleeneStar: Hashable, Sendable, ConvertibleToLanguage {
  public let language: Language

  public init(@LanguageBuilder _ content: () -> Language) {
    self.language = .kleeneStar(content())
  }
}
