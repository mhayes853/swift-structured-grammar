@resultBuilder
public enum GrammarBuilder {
  public static func buildExpression(_ rule: Rule) -> [Rule] {
    [rule]
  }

  public static func buildExpression(_ grammar: Grammar) -> [Rule] {
    Array(grammar.rules)
  }

  public static func buildExpression(_ component: some GrammarComponent) -> [Rule] {
    Array(component.grammar.rules)
  }

  public static func buildBlock(_ components: [Rule]...) -> [Rule] {
    components.flatMap { $0 }
  }

  public static func buildOptional(_ component: [Rule]?) -> [Rule] {
    component ?? [Rule]()
  }

  public static func buildEither(first component: [Rule]) -> [Rule] {
    component
  }

  public static func buildEither(second component: [Rule]) -> [Rule] {
    component
  }

  public static func buildArray(_ components: [[Rule]]) -> [Rule] {
    components.flatMap { $0 }
  }
}
