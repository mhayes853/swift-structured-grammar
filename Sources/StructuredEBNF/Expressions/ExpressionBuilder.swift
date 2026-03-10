@resultBuilder
public enum ExpressionBuilder {
  public static func buildExpression(_ value: some ConvertibleToExpression) -> Expression {
    value.expression
  }

  public static func buildExpression(_ string: String) -> Expression {
    Terminal(string).expression
  }

  public static func buildBlock() -> Expression {
    .empty
  }

  public static func buildBlock(_ component: Expression) -> Expression {
    component
  }

  public static func buildBlock(_ components: Expression...) -> Expression {
    .concat(components)
  }

  public static func buildOptional(_ component: Expression?) -> Expression {
    component.expression
  }

  public static func buildEither(first component: Expression) -> Expression {
    component
  }

  public static func buildEither(second component: Expression) -> Expression {
    component
  }

  public static func buildArray(_ components: [Expression]) -> Expression {
    switch components.count {
    case 0: .empty
    case 1: components[0]
    default: .concat(components)
    }
  }
}
