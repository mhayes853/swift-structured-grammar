extension Optional: LanguageComponent where Wrapped: LanguageComponent {
  public var language: Language {
    self.map { $0.language } ?? Language()
  }
}
