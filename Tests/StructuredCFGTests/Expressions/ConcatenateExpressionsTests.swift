import CustomDump
import Testing
import StructuredCFG

@Suite
struct `ConcatenateExpressions tests` {
  @Test
  func `Formats As Concatenation`() {
    let production = Rule("start") {
      ConcatenateExpressions {
        "a"
        Ref("target")
      }
    }
    let grammar = Grammar(production)

    expectNoDifference(try! grammar.formatted(with: .w3cEbnf), #"start ::= "a" target"#)
  }
}
