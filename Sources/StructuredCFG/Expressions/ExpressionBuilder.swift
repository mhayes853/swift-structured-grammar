/// A result builder for constructing ``Expression`` values from expression components.
@resultBuilder
public enum ExpressionBuilder {
  @inlinable
  public static func buildExpression(_ value: some Expression.Component) -> Expression {
    value.expression
  }

  @inlinable
  public static func buildExpression(_ expression: Expression) -> Expression {
    expression
  }

  @inlinable
  public static func buildExpression(_ string: String) -> Expression {
    Terminal(string).expression
  }

  @inlinable
  public static func buildBlock() -> Expression {
    .epsilon
  }

  @inlinable
  public static func buildBlock(_ component: Expression) -> Expression {
    component
  }

  @inlinable
  public static func buildBlock(_ components: Expression...) -> Expression {
    .concat(components)
  }

  @inlinable
  public static func buildOptional(_ component: Expression?) -> Expression {
    component.expression
  }

  @inlinable
  public static func buildEither(first component: Expression) -> Expression {
    component
  }

  @inlinable
  public static func buildEither(second component: Expression) -> Expression {
    component
  }

  @inlinable
  public static func buildArray(_ components: [Expression]) -> Expression {
    switch components.count {
    case 0: .epsilon
    case 1: components[0]
    default: .concat(components)
    }
  }
}
