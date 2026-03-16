import CustomDump
import Testing
import StructuredCFG

@Suite
struct `ZeroOrMore tests` {
  @Test
  func `Formats As Repetition`() {
    let production = Rule("start") {
      ZeroOrMore {
        "a"
      }
    }
    let grammar = Grammar(production)

    expectNoDifference(try! grammar.formatted(with: .w3cEbnf), #"start ::= "a"*"#)
  }
}
