import CustomDump
import Testing
import StructuredCFG

@Suite
struct `OneOrMore tests` {
  @Test
  func `Direct Initialization Builds One Or More Expression`() {
    let expression = OneOrMore { "value" }.expression
    expectNoDifference(expression, .oneOrMore(.terminal("value")))
  }

  @Test
  func `Formats As Canonical Concatenation And Repetition`() {
    let production = Production("start") {
      OneOrMore {
        "value"
      }
    }
    let grammar = Grammar(production)

    expectNoDifference(try! grammar.formatted(with: .w3cEbnf), #"start ::= "value"+"#)
  }
}
