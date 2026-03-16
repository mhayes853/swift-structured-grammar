import CustomDump
import Testing
import StructuredCFG

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
}
