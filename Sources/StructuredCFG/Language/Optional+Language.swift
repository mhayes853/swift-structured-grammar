extension Optional: LanguageComponent where Wrapped: LanguageComponent {
  public var language: Language {
    guard let wrapped = self else { return Language() }
    return wrapped.language
  }
}
