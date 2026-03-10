@resultBuilder
public enum GrammarBuilder {
  public static func buildExpression(_ production: Production) -> [Production] {
    [production]
  }

  public static func buildExpression(_ grammar: Grammar) -> [Production] {
    Array(grammar.productions)
  }

  public static func buildBlock(_ components: [Production]...) -> [Production] {
    components.flatMap { $0 }
  }

  public static func buildOptional(_ component: [Production]?) -> [Production] {
    component ?? [Production]()
  }

  public static func buildEither(first component: [Production]) -> [Production] {
    component
  }

  public static func buildEither(second component: [Production]) -> [Production] {
    component
  }

  public static func buildArray(_ components: [[Production]]) -> [Production] {
    components.flatMap { $0 }
  }
}
