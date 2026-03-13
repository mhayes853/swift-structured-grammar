import CustomDump
import Testing
import StructuredCFG

@Suite
struct `GrammarNameResolver tests` {
  @Test
  func `Default Resolver Uses Validator Safe Prefix For Union Conflicts`() {
    let language = Union {
      Grammar(startingSymbol: "expression") {
        Production("expression") { "first" }
        Production("term") { "value" }
      }
      Grammar(startingSymbol: "expression") {
        Production("expression") { "second" }
        Production("factor") { "other" }
      }
    }

    let grammar = language.language.grammar()

    expectNoDifference(
      grammar.productions.map(\.symbol.rawValue).sorted(),
      ["expression", "factor", "gbexpression", "lastart", "root", "term"]
    )
  }

  @Test
  func `Default Resolver Uses Validator Safe Prefix For Concatenate Conflicts`() {
    let language = ConcatenateLanguages {
      Grammar(startingSymbol: "term") {
        Production("term") { "first" }
        Production("factor") { "value" }
      }
      Grammar(startingSymbol: "term") {
        Production("term") { "second" }
        Production("factor") { "other" }
      }
    }

    let grammar = language.language.grammar()

    expectNoDifference(
      grammar.productions.map(\.symbol.rawValue).sorted(),
      ["factor", "gbfactor", "gbterm", "lastart", "root", "term"]
    )
  }

  @Test
  func `Default Resolver Uses Validator Safe Prefix For Synthesized Symbols`() {
    let language = Union {
      Grammar(startingSymbol: "a") {
        Production("a") { "x" }
      }
      Grammar(startingSymbol: "b") {
        Production("b") { "y" }
      }
    }

    let grammar = language.language.grammar()

    let synthesizedSymbols = grammar.productions.filter {
      $0.symbol.rawValue.hasPrefix("l") && $0.symbol.rawValue.hasSuffix("start")
    }

    expectNoDifference(synthesizedSymbols.map(\.symbol.rawValue), ["lastart"])
  }

  @Test
  func `Default Resolver Uses Alphabetic Rollover For Conflicts`() {
    let grammars = (0...753).map { index in
      Grammar(startingSymbol: "expression") {
        Production("expression") { "value-\(index)" }
      }
    }

    let grammar = Language.union(grammars).grammar()

    #expect(grammar.containsProduction(for: "gaaexpression"))
    #expect(grammar.containsProduction(for: "gabzexpression"))
  }

  @Test
  func `Custom Resolver Is Used For Symbol Conflicts`() {
    struct CustomResolver: Language.GrammarNameResolver {
      func resolveSymbolConflict(
        for new: Language.ResolvableGrammarSymbol,
        against existing: Language.ResolvableGrammarSymbol,
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        return Symbol(rawValue: "custom__\(new.symbol.rawValue)")!
      }

      func createNewSymbol(
        grammars: [Grammar],
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        return Symbol(rawValue: "lsynth__\(context.grammarIndex)")!
      }
    }

    let language = Union {
      Grammar(startingSymbol: "expression") {
        Production("expression") { "first" }
      }
      Grammar(startingSymbol: "expression") {
        Production("expression") { "second" }
      }
    }

    let grammar = language.language.grammar(nameResolver: CustomResolver())

    expectNoDifference(
      grammar.productions.map(\.symbol.rawValue).sorted(),
      ["custom__expression", "expression", "lsynth__0", "root"]
    )
  }

  @Test
  func `Custom Resolver Can Choose To Keep Original Symbol`() {
    struct KeepOriginalNameResolver: Language.GrammarNameResolver {
      func resolveSymbolConflict(
        for new: Language.ResolvableGrammarSymbol,
        against existing: Language.ResolvableGrammarSymbol,
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        return existing.symbol
      }

      func createNewSymbol(
        grammars: [Grammar],
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        return Symbol(rawValue: "l\(context.grammarIndex)start")!
      }
    }

    let language = Union {
      Grammar(startingSymbol: "expression") {
        Production("expression") { "first" }
      }
      Grammar(startingSymbol: "expression") {
        Production("expression") { "second" }
      }
    }

    let grammar = language.language.grammar(nameResolver: KeepOriginalNameResolver())

    let expressionProds = grammar.productions.filter { $0.symbol.rawValue == "expression" }
    expectNoDifference(expressionProds.count, 1)
    expectNoDifference(expressionProds.first?.expression, Expression.terminal("second"))
  }

  @Test
  func `Context Grammar Index Increments For Each Merged Grammar`() {
    struct IndexCapturingResolver: Language.GrammarNameResolver {
      func resolveSymbolConflict(
        for new: Language.ResolvableGrammarSymbol,
        against existing: Language.ResolvableGrammarSymbol,
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        return Symbol(rawValue: "idx\(context.grammarIndex)__\(new.symbol.rawValue)")!
      }

      func createNewSymbol(
        grammars: [Grammar],
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        return Symbol(rawValue: "idx\(context.grammarIndex)__lstart")!
      }
    }

    let language = Union {
      Grammar(startingSymbol: "expr") { Production("expr") { "x" } }
      Grammar(startingSymbol: "expr") { Production("expr") { "y" } }
      Grammar(startingSymbol: "expr") { Production("expr") { "z" } }
    }
    let grammar = language.language.grammar(nameResolver: IndexCapturingResolver())

    let conflictSymbols = grammar.productions.filter { $0.symbol.rawValue.hasPrefix("idx1__") || $0.symbol.rawValue.hasPrefix("idx2__") }
    expectNoDifference(conflictSymbols.count, 2)
  }

  @Test
  func `Kleene Star Synthesis Uses Default Resolver`() {
    let language = KleeneStar {
      Grammar(startingSymbol: "item") {
        Production("item") { "a" }
      }
    }

    let grammar = language.language.grammar()

    let synthesizedSymbols = grammar.productions.filter {
      $0.symbol.rawValue.hasPrefix("l") && $0.symbol.rawValue.hasSuffix("start")
    }

    expectNoDifference(synthesizedSymbols.map(\.symbol.rawValue), ["lastart"])
  }

  @Test
  func `Context Grammars Array Contains All Grammars In Union`() {
    struct GrammarCapturingResolver: Language.GrammarNameResolver {
      func resolveSymbolConflict(
        for new: Language.ResolvableGrammarSymbol,
        against existing: Language.ResolvableGrammarSymbol,
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        let count = context.grammars.count
        return Symbol(rawValue: "grammars\(count)__\(new.symbol.rawValue)")!
      }

      func createNewSymbol(
        grammars: [Grammar],
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        let count = grammars.count
        return Symbol(rawValue: "grammars\(count)__lstart")!
      }
    }

    let grammar1 = Grammar(startingSymbol: "a") { Production("a") { "x" } }
    let grammar2 = Grammar(startingSymbol: "b") { Production("b") { "y" } }
    let grammar3 = Grammar(startingSymbol: "c") { Production("c") { "z" } }

    let language = Union {
      grammar1
      grammar2
      grammar3
    }
    let grammar = language.language.grammar(nameResolver: GrammarCapturingResolver())

    let synthesizedSymbols = grammar.productions.filter { $0.symbol.rawValue.hasPrefix("grammars3__") }
    expectNoDifference(synthesizedSymbols.isEmpty, false)
  }
}
