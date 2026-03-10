import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `ConcatanateExpressions tests` {
  @Test
  func `Formats As Concatenation`() {
    let grammar = Grammar {
      Production("start") {
        ConcatanateExpressions {
          "a"
          Ref("target")
        }
      }
    }

    expectNoDifference(grammar.formatted(), "start = \"a\", target ;")
  }
}
