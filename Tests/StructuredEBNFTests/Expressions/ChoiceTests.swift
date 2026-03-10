import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `Choice tests` {
  @Test
  func `Formats As Alternation`() {
    let grammar = Grammar {
      Production("start") {
        Choice {
          "a"
          "b"
        }
      }
    }

    expectNoDifference(grammar.formatted(), "start = \"a\" | \"b\" ;")
  }
}
