import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `Ref tests` {
  @Test
  func `Formats As Referenced Identifier`() {
    let grammar = Grammar {
      Production("start") {
        Ref("target")
      }
    }

    expectNoDifference(grammar.formatted(), "start = target ;")
  }
}
