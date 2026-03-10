import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `Group tests` {
  @Test
  func `Formats As Parenthesized Expression`() {
    let grammar = Grammar {
      Production("start") {
        Group {
          "a"
          Ref("target")
        }
      }
    }

    expectNoDifference(grammar.formatted(), "start = (\"a\", target) ;")
  }
}
