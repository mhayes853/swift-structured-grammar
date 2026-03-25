extension Optional: Language.Component where Wrapped: Language.Component {
  public var language: Language {
    self.map { $0.language } ?? Language()
  }
}
