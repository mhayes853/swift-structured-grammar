extension Optional: ConvertibleToLanguage where Wrapped: ConvertibleToLanguage {
  public var language: Language {
    guard let wrapped = self else { return Language() }
    return wrapped.language
  }
}
