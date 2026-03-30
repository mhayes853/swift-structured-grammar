import CustomDump
import Testing
import StructuredCFG

@Suite
struct `OptionalExpression tests` {
  @Test
  func `Formats As Optional Expression`() {
    let production = Rule("start") {
      OptionalExpression {
        "a"
      }
    }
    let grammar = Grammar(production)

    expectNoDifference(try! grammar.formatted(with: .w3cEbnf), #"start ::= "a"?"#)
  }
}
