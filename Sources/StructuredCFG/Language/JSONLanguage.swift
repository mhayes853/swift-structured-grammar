public struct JSONLanguage: LanguageComponent {
  public let asciiOnly: Bool

  public var language: Language {
    Language { JSONGrammar(asciiOnly: self.asciiOnly).grammar }
  }

  public init(asciiOnly: Bool = false) {
    self.asciiOnly = asciiOnly
  }
}
