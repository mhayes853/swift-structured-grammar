import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `Concat tests` {
  @Test
  func `Formats As Concatenation`() {
    let grammar = Grammar {
      Production("start") {
        Concat {
          "a"
          Ref("target")
        }
      }
    }

    expectNoDifference(grammar.formatted(), "start = \"a\", target ;")
  }
}
