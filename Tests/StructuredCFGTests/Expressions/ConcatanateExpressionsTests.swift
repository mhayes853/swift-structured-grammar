import CustomDump
import Testing
import StructuredCFG

@Suite
struct `ConcatanateExpressions tests` {
  @Test
  func `Formats As Concatenation`() {
    let production = Production("start") {
      ConcatenateExpressions {
        "a"
        Ref("target")
      }
    }
    let grammar = Grammar(production)

    expectNoDifference(try! grammar.formatted(with: .w3cEbnf), #"start ::= "a" target"#)
  }
}
