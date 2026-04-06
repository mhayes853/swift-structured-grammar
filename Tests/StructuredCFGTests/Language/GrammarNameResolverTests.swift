import CustomDump
import IssueReporting
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

    expectNoDifference(grammar.containsRule(for: "gaaexpression"), true)
    expectNoDifference(grammar.containsRule(for: "gabzexpression"), true)
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
  func `Resolver Receives Updated Existing Symbols For Cascading Conflicts`() {
    struct ExistingSymbolsResolver: Language.GrammarSymbolResolver {
      final class State: Sendable {
        let attempts = Lock(0)
        let sawExistingR2 = Lock(false)
      }

      let state = State()

      func resolveSymbolConflict(
        for new: Language.ResolvableGrammarSymbol,
        against existing: Language.ResolvableGrammarSymbol,
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        if new.symbol.rawValue == "r1" {
          return Symbol(rawValue: "r2")
        }
        if context.existingSymbols.contains(Symbol(rawValue: "r2")) {
          self.state.sawExistingR2.withLock { $0 = true }
          let attempt = self.state.attempts.withLock {
            $0 += 1
            return $0
          }
          if attempt == 1 {
            return Symbol(rawValue: "resolved__r2")
          }
          return Symbol(rawValue: "resolved__r1")
        }
        return Symbol(rawValue: "r2")
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

    let resolver = ExistingSymbolsResolver()
    let grammar = language.language.grammar(symbolResolver: resolver)

    let sawExistingR2 = resolver.state.sawExistingR2.withLock { $0 }
    let r1Rule = grammar.rules.first { $0.symbol.rawValue == "resolved__r1" }

    expectNoDifference(sawExistingR2, true)
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

  @Test(.timeLimit(.minutes(1)))
  func `Suspicious Resolver Cycles Report An Issue`() async throws {
    struct CyclingResolver: Language.GrammarSymbolResolver {
      func resolveSymbolConflict(
        for new: Language.ResolvableGrammarSymbol,
        against existing: Language.ResolvableGrammarSymbol,
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        existing.symbol
      }

      func createNewSymbol(
        grammars: [Grammar],
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        Symbol(rawValue: "lsynth__\(context.grammarIndex)")
      }
    }

    struct CapturingIssueReporter: IssueReporter, Sendable {
      let continuation: AsyncStream<String>.Continuation

      func reportIssue(
        _ message: @autoclosure () -> String?,
        severity: IssueSeverity,
        fileID: StaticString,
        filePath: StaticString,
        line: UInt,
        column: UInt
      ) {
        self.continuation.yield(message() ?? "")
      }
    }

    let language = Union {
      Grammar(startingSymbol: "start") {
        Rule("start") { "left" }
        Rule("claimed") { "first" }
      }
      Grammar(startingSymbol: "start") {
        Rule("start") { "right" }
        Rule("claimed") { "second" }
      }
    }

    let (stream, continuation) = AsyncStream<String>.makeStream()
    var iterator = stream.makeAsyncIterator()
    let reporter = CapturingIssueReporter(continuation: continuation)

    Task {
      withIssueReporters([reporter]) {
        language.language.grammar(symbolResolver: CyclingResolver())
      }
    }

    let message = try #require(await iterator.next())
    expectNoDifference(message.contains("resolving"), true)
  }

  @Test
  func `Suspicious Resolver Cycles Report Only Once Per Conflict`() {
    struct CyclingResolver: Language.GrammarSymbolResolver {
      final class State: Sendable {
        let count = Lock(0)
      }

      let state = State()

      func resolveSymbolConflict(
        for new: Language.ResolvableGrammarSymbol,
        against existing: Language.ResolvableGrammarSymbol,
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        let count = self.state.count.withLock {
          $0 += 1
          return $0
        }
        if count <= 150 {
          return Symbol(rawValue: "claimed")
        }
        return Symbol(rawValue: "resolved__\(new.symbol.rawValue)")
      }

      func createNewSymbol(
        grammars: [Grammar],
        context: Language.GrammarNameResolutionContext
      ) -> Symbol {
        Symbol(rawValue: "lsynth__\(context.grammarIndex)")
      }
    }

    final class CapturingIssueReporter: IssueReporter, Sendable {
      let messages = Lock([String]())

      func reportIssue(
        _ message: @autoclosure () -> String?,
        severity: IssueSeverity,
        fileID: StaticString,
        filePath: StaticString,
        line: UInt,
        column: UInt
      ) {
        self.messages.withLock {
          $0.append(message() ?? "")
        }
      }
    }

    let language = Union {
      Grammar(startingSymbol: "start") {
        Rule("start") { "left" }
        Rule("claimed") { "first" }
      }
      Grammar(startingSymbol: "start") {
        Rule("start") { "right" }
        Rule("claimed") { "second" }
      }
    }

    let reporter = CapturingIssueReporter()
    _ = withIssueReporters([reporter]) {
      language.language.grammar(symbolResolver: CyclingResolver())
    }
    let messages = reporter.messages.withLock { $0 }

    expectNoDifference(messages.count, 1)
  }
}
