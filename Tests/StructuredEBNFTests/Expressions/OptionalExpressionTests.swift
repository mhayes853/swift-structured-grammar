import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `OptionalExpression tests` {
  @Test
  func `Formats As Optional Expression`() {
    let production = Production("start") {
      OptionalExpression {
        "a"
      }
    }
    let grammar = Grammar(production)

    expectNoDifference(grammar.formatted(), "start = [\"a\"] ;")
  }
}
