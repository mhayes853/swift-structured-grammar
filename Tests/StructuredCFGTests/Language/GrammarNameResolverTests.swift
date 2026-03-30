import CustomDump
import StructuredCFG
import Testing

@Suite
struct `GrammarNameResolver tests` {
  @Test
  func `Default Resolver Uses Validator Safe Prefix For Union Conflicts`() {
    let language = Union {
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "first" }
        Rule("term") { "value" }
      }
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "second" }
        Rule("factor") { "other" }
      }
    }

    let grammar = language.language.grammar()

    expectNoDifference(
      grammar.rules.map(\.symbol.rawValue).sorted(),
      ["expression", "factor", "gbexpression", "lastart", "root", "term"]
    )
  }

  @Test
  func `Default Resolver Uses Validator Safe Prefix For Concatenate Conflicts`() {
    let language = ConcatenateLanguages {
      Grammar(startingSymbol: "term") {
        Rule("term") { "first" }
        Rule("factor") { "value" }
      }
      Grammar(startingSymbol: "term") {
        Rule("term") { "second" }
        Rule("factor") { "other" }
      }
    }

    let grammar = language.language.grammar()

    expectNoDifference(
      grammar.rules.map(\.symbol.rawValue).sorted(),
      ["factor", "gbfactor", "gbterm", "lastart", "root", "term"]
    )
  }

  @Test
  func `Default Resolver Uses Validator Safe Prefix For Synthesized Symbols`() {
    let language = Union {
      Grammar(startingSymbol: "a") {
        Rule("a") { "x" }
      }
      Grammar(startingSymbol: "b") {
        Rule("b") { "y" }
      }
    }

    let grammar = language.language.grammar()

    let synthesizedSymbols = grammar.rules.filter {
      $0.symbol.rawValue.hasPrefix("l") && $0.symbol.rawValue.hasSuffix("start")
    }

    expectNoDifference(synthesizedSymbols.map(\.symbol.rawValue), ["lastart"])
  }

  @Test
  func `Default Resolver Uses Alphabetic Rollover For Conflicts`() {
    let grammars = (0...753)
      .map { index in
        Grammar(startingSymbol: "expression") {
          Rule("expression") { "value-\(index)" }
        }
      }

    let grammar = Language.union(grammars).grammar()

    #expect(grammar.containsRule(for: "gaaexpression"))
    #expect(grammar.containsRule(for: "gabzexpression"))
  }

  @Test
  func `Custom Resolver Is Used For Symbol Conflicts`() {
    struct CustomResolver: Language.GrammarSymbolResolver {
      func resolveSymbolConflict(
        for new: Language.ResolvableGrammarSymbol,
        against existing: Language.ResolvableGrammarSymbol,
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        return Symbol(rawValue: "custom__\(new.symbol.rawValue)")
      }

      func createNewSymbol(
        grammars: [Grammar],
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        return Symbol(rawValue: "lsynth__\(context.grammarIndex)")
      }
    }

    let language = Union {
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "first" }
      }
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "second" }
      }
    }

    let grammar = language.language.grammar(symbolResolver: CustomResolver())

    expectNoDifference(
      grammar.rules.map(\.symbol.rawValue).sorted(),
      ["custom__expression", "expression", "lsynth__0", "root"]
    )
  }

  @Test
  func `Context Grammar Index Increments For Each Merged Grammar`() {
    struct IndexCapturingResolver: Language.GrammarSymbolResolver {
      func resolveSymbolConflict(
        for new: Language.ResolvableGrammarSymbol,
        against existing: Language.ResolvableGrammarSymbol,
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        return Symbol(rawValue: "idx\(context.grammarIndex)__\(new.symbol.rawValue)")
      }

      func createNewSymbol(
        grammars: [Grammar],
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        return Symbol(rawValue: "idx\(context.grammarIndex)__lstart")
      }
    }

    let language = Union {
      Grammar(startingSymbol: "expr") { Rule("expr") { "x" } }
      Grammar(startingSymbol: "expr") { Rule("expr") { "y" } }
      Grammar(startingSymbol: "expr") { Rule("expr") { "z" } }
    }
    let grammar = language.language.grammar(symbolResolver: IndexCapturingResolver())

    let conflictSymbols = grammar.rules.filter {
      $0.symbol.rawValue.hasPrefix("idx1__") || $0.symbol.rawValue.hasPrefix("idx2__")
    }
    expectNoDifference(conflictSymbols.count, 2)
  }

  @Test
  func `Star Synthesis Uses Default Resolver`() {
    let language = Star {
      Grammar(startingSymbol: "item") {
        Rule("item") { "a" }
      }
    }

    let grammar = language.language.grammar()

    let synthesizedSymbols = grammar.rules.filter {
      $0.symbol.rawValue.hasPrefix("l") && $0.symbol.rawValue.hasSuffix("start")
    }

    expectNoDifference(synthesizedSymbols.map(\.symbol.rawValue), ["lastart"])
  }

  @Test
  func `Resolver Is Called Again When Resolved Symbol Creates New Conflict`() {
    struct ResolverThatCreatesCascade: Language.GrammarSymbolResolver {
      func resolveSymbolConflict(
        for new: Language.ResolvableGrammarSymbol,
        against existing: Language.ResolvableGrammarSymbol,
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        if new.symbol.rawValue == "r1" {
          return Symbol(rawValue: "r2")
        }
        return Symbol(rawValue: "resolved__\(new.symbol.rawValue)")
      }

      func createNewSymbol(
        grammars: [Grammar],
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        let namespace = context.grammarIndex > 0 ? "b" : "a"
        return Symbol(rawValue: "l\(namespace)start")
      }
    }

    let language = Union {
      Grammar(startingSymbol: "start") {
        Rule("r1") { "a" }
        Rule("r2") { "b" }
      }
      Grammar(startingSymbol: "start") {
        Rule("r1") { "c" }
      }
    }

    let grammar = language.language.grammar(symbolResolver: ResolverThatCreatesCascade())

    let r1Rule = grammar.rules.first { $0.symbol.rawValue == "resolved__r2" }
    expectNoDifference(r1Rule != nil, true)
  }

  @Test
  func `Context Grammars Array Contains All Grammars In Union`() {
    struct GrammarCapturingResolver: Language.GrammarSymbolResolver {
      func resolveSymbolConflict(
        for new: Language.ResolvableGrammarSymbol,
        against existing: Language.ResolvableGrammarSymbol,
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        let count = context.grammars.count
        return Symbol(rawValue: "grammars\(count)__\(new.symbol.rawValue)")
      }

      func createNewSymbol(
        grammars: [Grammar],
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        let count = grammars.count
        return Symbol(rawValue: "grammars\(count)__lstart")
      }
    }

    let grammar1 = Grammar(startingSymbol: "a") { Rule("a") { "x" } }
    let grammar2 = Grammar(startingSymbol: "b") { Rule("b") { "y" } }
    let grammar3 = Grammar(startingSymbol: "c") { Rule("c") { "z" } }

    let language = Union {
      grammar1
      grammar2
      grammar3
    }
    let grammar = language.language.grammar(symbolResolver: GrammarCapturingResolver())

    let synthesizedSymbols = grammar.rules.filter { $0.symbol.rawValue.hasPrefix("grammars3__") }
    expectNoDifference(synthesizedSymbols.isEmpty, false)
  }
}
