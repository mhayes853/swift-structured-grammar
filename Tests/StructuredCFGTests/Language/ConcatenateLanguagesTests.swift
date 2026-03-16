import CustomDump
import Testing
import StructuredCFG

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
}
