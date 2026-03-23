import CustomDump
import StructuredCFG
import Testing

@Suite
struct `Union tests` {
  @Test
  func `Union Builds Choice Over Distinct Grammar Entry Productions`() {
    let language = Union {
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "first" }
        Rule("term") { "value" }
      }
      Grammar(startingSymbol: "statement") {
        Rule("statement") { "second" }
        Rule("factor") { Ref("term") }
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("lastart") }
        Rule("expression") { "first" }
        Rule("term") { "value" }
        Rule("statement") { "second" }
        Rule("factor") { Ref("term") }
        Rule("lastart") {
          Choice {
            Ref("expression")
            Ref("statement")
          }
        }
      }
    )
  }

  @Test
  func `Union Builder Supports Conditional Branches`() {
    let usePrimary = true
    let language = Union {
      if usePrimary {
        Grammar(Rule("expression") { "value" })
      } else {
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
  func `Union Formats As W3C Choice Over Entry Productions`() throws {
    let language = Union {
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "left" }
      }
      Grammar(startingSymbol: "statement") {
        Rule("statement") { "right" }
      }
    }

    expectNoDifference(
      try language.language.formatted(with: .w3cEbnf),
      """
      root ::= lastart
      expression ::= "left"
      statement ::= "right"
      lastart ::= expression | statement
      """
    )
  }

  @Test
  func `Union XGrammar Matches Either Branch`() async throws {
    let language = Union {
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "left" }
      }
      Grammar(startingSymbol: "statement") {
        Rule("statement") { "right" }
      }
    }
    .language

    let leftMatches = try await XGrammarTestSupport.matches("left", language: language)
    let rightMatches = try await XGrammarTestSupport.matches("right", language: language)
    let invalidMatches = try await XGrammarTestSupport.matches("other", language: language)

    expectNoDifference(leftMatches, true)
    expectNoDifference(rightMatches, true)
    expectNoDifference(invalidMatches, false)
  }
}
