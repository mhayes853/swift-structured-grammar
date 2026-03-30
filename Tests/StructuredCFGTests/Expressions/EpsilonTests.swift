import CustomDump
import Testing
import StructuredCFG

@Suite
struct `Epsilon tests` {
  @Test
  func `Epsilon Produces Epsilon Expression`() {
    expectNoDifference(Epsilon().expression, Expression.epsilon)
  }

  @Test
  func `Epsilon Is Preserved In Choice`() {
    let grammar = Grammar(Rule("start") {
      ChoiceOf {
        Epsilon()
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: .gbnf),
      #"start ::= "" | "a""#
    )
  }
}
