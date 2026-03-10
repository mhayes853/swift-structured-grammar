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
        Production("expression") { "second" }
      }
    }

    expectNoDifference(
      language.language.grammar,
      Grammar {
        Production("g0__expression") { "first" }
        Production("g0__term") { "value" }
        Production("g1__factor") { Ref("g1__term") }
        Production("g1__expression") { "second" }
        Production("l0__start") {
          Ref("g0__expression")
          Ref("g1__factor")
        }
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
      language.language.grammar,
      Grammar {
        Production("g0__expression") { "value" }
        Production("l0__start") { Ref("g0__expression") }
      }
    )
  }
}
