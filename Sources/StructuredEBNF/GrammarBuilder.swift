@resultBuilder
public enum GrammarBuilder {
  public static func buildExpression(_ production: Production) -> Grammar {
    var grammar = Grammar()
    grammar.replaceProduction(named: production.identifier, with: production.expression)
    return grammar
  }

  public static func buildExpression(_ grammar: Grammar) -> Grammar {
    grammar
  }

  public static func buildBlock(_ components: Grammar...) -> Grammar {
    components.reduce(into: Grammar()) { partialResult, grammar in
      partialResult.merge(grammar)
    }
  }

  public static func buildOptional(_ component: Grammar?) -> Grammar {
    component ?? Grammar()
  }

  public static func buildEither(first component: Grammar) -> Grammar {
    component
  }

  public static func buildEither(second component: Grammar) -> Grammar {
    component
  }

  public static func buildArray(_ components: [Grammar]) -> Grammar {
    components.reduce(into: Grammar()) { partialResult, grammar in
      partialResult.merge(grammar)
    }
  }
}
