/// A result builder for constructing the alternatives of a ``ChoiceOf``.
@resultBuilder
public enum ChoiceBuilder {
  @inlinable
  public static func buildExpression(_ value: some Expression.Component) -> [Expression] {
    [value.expression]
  }

  @inlinable
  public static func buildExpression(_ string: String) -> [Expression] {
    [Terminal(string).expression]
  }

  @inlinable
  public static func buildBlock(_ components: [Expression]...) -> [Expression] {
    components.flatMap { $0 }
  }

  @inlinable
  public static func buildOptional(_ component: [Expression]?) -> [Expression] {
    component ?? [Expression]()
  }

  @inlinable
  public static func buildArray(_ components: [[Expression]]) -> [Expression] {
    components.flatMap { $0 }
  }

  @inlinable
  public static func buildEither(first component: [Expression]) -> [Expression] {
    component
  }

  @inlinable
  public static func buildEither(second component: [Expression]) -> [Expression] {
    component
  }
}
