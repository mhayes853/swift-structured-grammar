public struct Concatenate: Hashable, Sendable, ConvertibleToLanguage {
  public let language: Language

  public init(@ConcatenateBuilder _ content: () -> [Language]) {
    self.language = Language.concatenate(content())
  }
}
