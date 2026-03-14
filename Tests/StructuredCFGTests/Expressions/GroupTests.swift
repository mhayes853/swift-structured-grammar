import CustomDump
import Testing
import StructuredCFG

@Suite
struct `Group tests` {
  @Test
  func `Formats As Parenthesized Expression`() {
    let production = Production("start") {
      Group {
        "a"
        Ref("target")
      }
    }
    let grammar = Grammar(production)

    expectNoDifference(try! grammar.formatted(with: .w3cEbnf), #"start ::= ("a" target)"#)
  }
}
