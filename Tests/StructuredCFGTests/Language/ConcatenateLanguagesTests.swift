import CustomDump
import Testing
import StructuredCFG

@Suite
struct `ConcatenateLanguages tests` {
  @Test
  func `ConcatenateLanguages Merges Grammars In Encounter Order`() {
    let language = ConcatenateLanguages {
      Grammar(startingSymbol: "expression") {
        Production("expression") { "first" }
        Production("term") { "value" }
      }
      Grammar(startingSymbol: "factor") {
        Production("factor") { Ref("term") }
        Production("statement") { "second" }
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(startingSymbol: .root) {
        Production(.root) { Ref("lastart") }
        Production("expression") { "first" }
        Production("term") { "value" }
        Production("factor") { Ref("term") }
        Production("statement") { "second" }
        Production("lastart") {
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
      Grammar(Production("expression") { "value" })
      if includeExtra {
        Grammar(Production("term") { "other" })
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(startingSymbol: .root) {
        Production(.root) { Ref("lastart") }
        Production("expression") { "value" }
        Production("lastart") { Ref("expression") }
      }
    )
  }
}
