public struct ConcatenateLanguages: Hashable, Sendable, ConvertibleToLanguage {
  public let language: Language

  public init(@ConcatenateLanguagesBuilder _ content: () -> [Language]) {
    self.language = .concatenate(content())
  }
}
