/// A result builder for constructing ``Expression`` values from expression components.
@resultBuilder
public enum ExpressionBuilder {
  public static func buildExpression(_ value: some ExpressionComponent) -> Expression {
    value.expression
  }

  public static func buildExpression(_ expression: Expression) -> Expression {
    expression
  }

  public static func buildExpression(_ string: String) -> Expression {
    Terminal(string).expression
  }

  public static func buildBlock() -> Expression {
    .epsilon
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
    case 0: .epsilon
    case 1: components[0]
    default: .concat(components)
    }
  }
}
