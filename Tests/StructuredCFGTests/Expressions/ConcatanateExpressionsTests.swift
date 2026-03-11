import CustomDump
import Testing
import StructuredCFG

@Suite
struct `ConcatanateExpressions tests` {
  @Test
  func `Formats As Concatenation`() {
    let production = Production("start") {
      ConcatanateExpressions {
        "a"
        Ref("target")
      }
    }
    let grammar = Grammar(production)

    expectNoDifference(grammar.formatted(), #"start ::= "a" target"#)
  }
}
