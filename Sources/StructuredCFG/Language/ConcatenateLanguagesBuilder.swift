/// A result builder for collecting inputs to ``ConcatenateLanguages``.
@resultBuilder
public enum ConcatenateLanguagesBuilder {
  @inlinable
  public static func buildExpression(_ value: some Language.Component) -> [Language] {
    [value.language]
  }

  @inlinable
  public static func buildBlock(_ components: [Language]...) -> [Language] {
    components.flatMap { $0 }
  }

  @inlinable
  public static func buildOptional(_ component: [Language]?) -> [Language] {
    component ?? [Language]()
  }

  @inlinable
  public static func buildEither(first component: [Language]) -> [Language] {
    component
  }

  @inlinable
  public static func buildEither(second component: [Language]) -> [Language] {
    component
  }

  @inlinable
  public static func buildArray(_ components: [[Language]]) -> [Language] {
    components.flatMap { $0 }
  }
}
