/// A result builder for constructing the alternatives of a ``ChoiceOf``.
@resultBuilder
public enum ChoiceBuilder {
  public static func buildExpression(_ value: some Expression.Component) -> [Expression] {
    [value.expression]
  }

  public static func buildExpression(_ string: String) -> [Expression] {
    [Terminal(string).expression]
  }

  public static func buildBlock(_ components: [Expression]...) -> [Expression] {
    components.flatMap { $0 }
  }

  public static func buildOptional(_ component: [Expression]?) -> [Expression] {
    component ?? [Expression]()
  }

  public static func buildArray(_ components: [[Expression]]) -> [Expression] {
    components.flatMap { $0 }
  }

  public static func buildEither(first component: [Expression]) -> [Expression] {
    component
  }

  public static func buildEither(second component: [Expression]) -> [Expression] {
    component
  }
}
