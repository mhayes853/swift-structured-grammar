import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `ConcatenateLanguages tests` {
  @Test
  func `ConcatenateLanguages Merges Grammars In Encounter Order`() {
    let language = ConcatenateLanguages {
      Grammar(startingIdentifier: "expression") {
        Production("expression") { "first" }
        Production("term") { "value" }
      }
      Grammar(startingIdentifier: "factor") {
        Production("factor") { Ref("term") }
        Production("statement") { "second" }
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(startingIdentifier: .root) {
        Production(.root) { Ref("l0__start") }
        Production("expression") { "first" }
        Production("term") { "value" }
        Production("factor") { Ref("term") }
        Production("statement") { "second" }
        Production("l0__start") {
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
      Grammar(startingIdentifier: .root) {
        Production(.root) { Ref("l0__start") }
        Production("expression") { "value" }
        Production("l0__start") { Ref("expression") }
      }
    )
  }
}
