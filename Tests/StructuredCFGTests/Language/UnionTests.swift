import CustomDump
import Testing
import StructuredCFG

@Suite
struct `Union tests` {
  @Test
  func `Union Builds Choice Over Distinct Grammar Entry Productions`() {
    let language = Union {
      Grammar(startingSymbol: "expression") {
        Production("expression") { "first" }
        Production("term") { "value" }
      }
      Grammar(startingSymbol: "statement") {
        Production("statement") { "second" }
        Production("factor") { Ref("term") }
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(startingSymbol: .root) {
        Production(.root) { Ref("l0__start") }
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
      }
    )
  }

  @Test
  func `Union Builder Supports Conditional Branches`() {
    let usePrimary = true
    let language = Union {
      if usePrimary {
        Grammar(Production("expression") { "value" })
      } else {
        Grammar(Production("term") { "other" })
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(startingSymbol: .root) {
        Production(.root) { Ref("l0__start") }
        Production("expression") { "value" }
        Production("l0__start") { Ref("expression") }
      }
    )
  }
}
