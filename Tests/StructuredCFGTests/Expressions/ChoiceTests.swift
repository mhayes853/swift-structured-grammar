import CustomDump
import Testing
import StructuredCFG

@Suite
struct `Choice tests` {
  @Test
  func `Formats As Alternation`() {
    let production = Rule("start") {
      ChoiceOf {
        "a"
        "b"
      }
    }
    let grammar = Grammar(production)

    expectNoDifference(try! grammar.formatted(with: .w3cEbnf), #"start ::= "a" | "b""#)
  }
}
