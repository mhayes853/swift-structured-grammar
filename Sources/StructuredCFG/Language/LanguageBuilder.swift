/// A result builder for constructing ``Language`` values from language components.
@resultBuilder
public enum LanguageBuilder {
  @inlinable
  public static func buildExpression(_ value: some Language.Component) -> Language {
    value.language
  }
  
  @inlinable
  public static func buildExpression(_ language: Language) -> Language {
    language
  }

  @inlinable
  public static func buildBlock() -> Language {
    Language()
  }

  @inlinable
  public static func buildBlock(_ component: Language) -> Language {
    component
  }

  @inlinable
  public static func buildOptional(_ component: Language?) -> Language {
    component.language
  }

  @inlinable
  public static func buildEither(first component: Language) -> Language {
    component
  }

  @inlinable
  public static func buildEither(second component: Language) -> Language {
    component
  }
}
