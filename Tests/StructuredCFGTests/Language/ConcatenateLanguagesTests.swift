import CustomDump
import StructuredCFG
import Testing

@Suite
struct `ConcatenateLanguages tests` {
  @Test
  func `ConcatenateLanguages Merges Grammars In Encounter Order`() {
    let language = ConcatenateLanguages {
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "first" }
        Rule("term") { "value" }
      }
      Grammar(startingSymbol: "factor") {
        Rule("factor") { Ref("term") }
        Rule("statement") { "second" }
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("lastart") }
        Rule("expression") { "first" }
        Rule("term") { "value" }
        Rule("factor") { Ref("term") }
        Rule("statement") { "second" }
        Rule("lastart") {
          Ref("expression")
          Ref("factor")
        }
      }
    )
  }

  @Test
  func `ConcatenateLanguages Builder Supports Optional Languages`() {
    let includeExtra = false
    let language = ConcatenateLanguages {
      Grammar(Rule("expression") { "value" })
      if includeExtra {
        Grammar(Rule("term") { "other" })
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("lastart") }
        Rule("expression") { "value" }
        Rule("lastart") { Ref("expression") }
      }
    )
  }

  @Test
  func `ConcatenateLanguages Formats As W3C Sequence Over Entry Productions`() throws {
    let language = ConcatenateLanguages {
      Grammar(startingSymbol: "prefix") {
        Rule("prefix") { "a" }
      }
      Grammar(startingSymbol: "suffix") {
        Rule("suffix") { "b" }
      }
    }

    expectNoDifference(
      try language.language.formatted(with: .w3cEbnf),
      """
      root ::= lastart
      prefix ::= "a"
      suffix ::= "b"
      lastart ::= prefix suffix
      """
    )
  }

  #if canImport(XGrammar)
  @Test
  func `ConcatenateLanguages XGrammar Matches Full Sequence Only`() async throws {
    let language = ConcatenateLanguages {
      Grammar(startingSymbol: "prefix") {
        Rule("prefix") { "a" }
      }
      Grammar(startingSymbol: "suffix") {
        Rule("suffix") { "b" }
      }
    }
    .language

    let fullMatch = try await XGrammarTestSupport.matches("ab", language: language)
    let partialMatch = try await XGrammarTestSupport.matches("a", language: language)
    let wrongOrderMatch = try await XGrammarTestSupport.matches("ba", language: language)

    expectNoDifference(fullMatch, true)
    expectNoDifference(partialMatch, false)
    expectNoDifference(wrongOrderMatch, false)
  }
  #endif

  @Test
  func `ConcatenateLanguages Rewrites Internal References When Conflicting Symbols Are Renamed`() {
    let language = ConcatenateLanguages {
      Grammar(startingSymbol: "start") {
        Rule("start") { Ref("expression") }
        Rule("expression") { "left" }
      }
      Grammar(startingSymbol: "start") {
        Rule("start") { Ref("expression") }
        Rule("expression") { "right" }
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("lastart") }
        Rule("start") { Ref("expression") }
        Rule("expression") { "left" }
        Rule("gbstart") { Ref("gbexpression") }
        Rule("gbexpression") { "right" }
        Rule("lastart") {
          Ref("start")
          Ref("gbstart")
        }
      }
    )
  }
}
