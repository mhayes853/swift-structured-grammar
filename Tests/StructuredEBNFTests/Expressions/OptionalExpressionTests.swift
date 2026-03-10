import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `OptionalExpression tests` {
  @Test
  func `Formats As Optional Expression`() {
    let grammar = Grammar {
      Production("start") {
        OptionalExpression {
          "a"
        }
      }
    }

    expectNoDifference(grammar.formatted(), "start = [\"a\"] ;")
  }
}
