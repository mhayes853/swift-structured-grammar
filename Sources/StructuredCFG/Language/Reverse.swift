public struct Reverse: Hashable, Sendable, ConvertibleToLanguage {
  public let language: Language

  public init(@LanguageBuilder _ content: () -> Language) {
    self.language = .reverse(content())
  }
}
