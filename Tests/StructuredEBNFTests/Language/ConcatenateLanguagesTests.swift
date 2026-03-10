import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `ConcatenateLanguages tests` {
  @Test
  func `ConcatenateLanguages Merges Grammars In Encounter Order`() {
    let language = ConcatenateLanguages {
      Grammar {
        Production("expression") { "first" }
        Production("term") { "value" }
      }
      Grammar {
        Production("factor") { Ref("term") }
        Production("statement") { "second" }
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar {
        Production("expression") { "first" }
        Production("term") { "value" }
        Production("factor") { Ref("term") }
        Production("statement") { "second" }
        Production("l0__start") {
          Ref("expression")
          Ref("factor")
        }
        Production(.root) { Ref("l0__start") }
      }
    )
  }

  @Test
  func `ConcatenateLanguages Builder Supports Optional Languages`() {
    let includeExtra = false
    let language = ConcatenateLanguages {
      Grammar {
        Production("expression") { "value" }
      }
      if includeExtra {
        Grammar {
          Production("term") { "other" }
        }
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar {
        Production("expression") { "value" }
        Production("l0__start") { Ref("expression") }
        Production(.root) { Ref("l0__start") }
      }
    )
  }
}
