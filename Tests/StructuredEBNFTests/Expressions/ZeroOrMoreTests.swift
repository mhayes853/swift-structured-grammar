import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `ZeroOrMore tests` {
  @Test
  func `Formats As Repetition`() {
    let production = Production("start") {
      ZeroOrMore {
        "a"
      }
    }
    let grammar = Grammar(production)

    expectNoDifference(grammar.formatted(), "start = {\"a\"} ;")
  }
}
