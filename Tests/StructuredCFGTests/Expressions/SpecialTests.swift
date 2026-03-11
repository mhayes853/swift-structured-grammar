import CustomDump
import Testing
import StructuredCFG

@Suite
struct `Special tests` {
  @Test
  func `Formats As Special Sequence`() {
    let production = Production("start") { Special("identifier") }
    let grammar = Grammar(production)

    expectNoDifference(grammar.formatted(), "start = ? identifier ? ;")
  }
}
