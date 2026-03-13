public protocol ConvertibleToLanguage {
  @LanguageBuilder
  var language: Language { get }
}
