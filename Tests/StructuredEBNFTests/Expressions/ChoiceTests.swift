import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `Choice tests` {
  @Test
  func `Formats As Alternation`() {
    let production = Production("start") {
      Choice {
        "a"
        "b"
      }
    }
    let grammar = Grammar(production)

    expectNoDifference(grammar.formatted(), "start = \"a\" | \"b\" ;")
  }
}
