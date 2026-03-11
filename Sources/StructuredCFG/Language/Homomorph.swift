public struct Homomorph: Hashable, Sendable, ConvertibleToLanguage {
  public let language: Language

  public init(
    _ terminal: Terminal,
    to replacement: Terminal,
    @LanguageBuilder _ content: () -> Language
  ) {
    let grammar = content().grammar().homomorphed(terminal, to: replacement)
    self.language = grammar.language
  }
}
