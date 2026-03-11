import CustomDump
import Testing
import StructuredCFG

@Suite
struct `Ref tests` {
  @Test
  func `Formats As Referenced Identifier`() {
    let production = Production("start") { Ref("target") }
    let grammar = Grammar(production)

    expectNoDifference(grammar.formatted(), "start ::= target")
  }
}
