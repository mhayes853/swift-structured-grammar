import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `Special tests` {
  @Test
  func `Formats As Special Sequence`() {
    let grammar = Grammar {
      Production("start") {
        Special("identifier")
      }
    }

    expectNoDifference(grammar.formatted(), "start = ? identifier ? ;")
  }
}
