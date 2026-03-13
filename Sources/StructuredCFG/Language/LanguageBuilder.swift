@resultBuilder
public enum LanguageBuilder {
  public static func buildExpression(_ value: some LanguageComponent) -> Language {
    value.language
  }
  
  public static func buildExpression(_ language: Language) -> Language {
    language
  }

  public static func buildBlock() -> Language {
    Language()
  }

  public static func buildBlock(_ component: Language) -> Language {
    component
  }

  public static func buildOptional(_ component: Language?) -> Language {
    component.language
  }

  public static func buildEither(first component: Language) -> Language {
    component
  }

  public static func buildEither(second component: Language) -> Language {
    component
  }
}
