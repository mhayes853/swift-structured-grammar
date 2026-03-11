import CustomDump
import Testing
import StructuredCFG

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

    expectNoDifference(grammar.formatted(), #"start ::= "a"*"#)
  }
}
