@resultBuilder
public enum ConcatenateLanguagesBuilder {
  public static func buildExpression(_ value: some ConvertibleToLanguage) -> [Language] {
    [value.language]
  }

  public static func buildBlock(_ components: [Language]...) -> [Language] {
    components.flatMap { $0 }
  }

  public static func buildOptional(_ component: [Language]?) -> [Language] {
    component ?? [Language]()
  }

  public static func buildEither(first component: [Language]) -> [Language] {
    component
  }

  public static func buildEither(second component: [Language]) -> [Language] {
    component
  }

  public static func buildArray(_ components: [[Language]]) -> [Language] {
    components.flatMap { $0 }
  }
}
