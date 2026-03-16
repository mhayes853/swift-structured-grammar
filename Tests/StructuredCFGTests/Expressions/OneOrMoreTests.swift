import CustomDump
import Testing
import StructuredCFG

@Suite
struct `OneOrMore tests` {
  @Test
  func `Direct Initialization Builds One Or More Expression`() {
    let expression = OneOrMore { "value" }.expression
    let expected = Repeat(min: 1, max: nil, Terminal("value")).expression
    expectNoDifference(expression, expected)
  }

  @Test
  func `Formats As Canonical Concatenation And Repetition`() {
    let production = Rule("start") {
      OneOrMore {
        "value"
      }
    }
    let grammar = Grammar(production)

    expectNoDifference(try! grammar.formatted(with: .w3cEbnf), #"start ::= "value"+"#)
  }
}
