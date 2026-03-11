public struct HomomorphMap: ConvertibleToLanguage {
  public let language: Language

  public init(
    @LanguageBuilder _ content: () -> Language,
    transform: (Terminal) -> Terminal?
  ) {
    let grammar = content().grammar().homomorphMapped(transform)
    self.language = grammar.language
  }
}
