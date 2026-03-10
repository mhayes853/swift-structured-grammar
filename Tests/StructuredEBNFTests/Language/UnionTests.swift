import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `Union tests` {
  @Test
  func `Union Builds Choice Over Distinct Grammar Entry Productions`() {
    let language = Union {
      Grammar {
        Production("expression") { "first" }
        Production("term") { "value" }
      }
      Grammar {
        Production("statement") { "second" }
        Production("factor") { Ref("term") }
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar {
        Production("expression") { "first" }
        Production("term") { "value" }
        Production("statement") { "second" }
        Production("factor") { Ref("term") }
        Production("l0__start") {
          Choice {
            Ref("expression")
            Ref("statement")
          }
        }
        Production(.root) { Ref("l0__start") }
      }
    )
  }

  @Test
  func `Union Builder Supports Conditional Branches`() {
    let usePrimary = true
    let language = Union {
      if usePrimary {
        Grammar {
          Production("expression") { "value" }
        }
      } else {
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
