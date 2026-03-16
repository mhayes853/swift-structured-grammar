import CustomDump
import Testing
import StructuredCFG

@Suite
struct `Ref tests` {
  @Test
  func `Formats As Referenced Identifier`() {
    let production = Rule("start") { Ref("target") }
    let grammar = Grammar(production)

    expectNoDifference(try! grammar.formatted(with: .w3cEbnf), "start ::= target")
  }
}
