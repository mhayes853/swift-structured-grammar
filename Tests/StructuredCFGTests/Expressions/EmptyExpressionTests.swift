import CustomDump
import Testing
import StructuredCFG

@Suite
struct `EmptyExpression tests` {
  @Test
  func `EmptyExpression Is Semantic Epsilon`() {
    expectNoDifference(EmptyExpression().expression, Expression.emptySequence)
  }

  @Test
  func `Semantic Epsilon Is Preserved In Choice`() {
    let grammar = Grammar(Rule("start") {
      Choice {
        EmptyExpression()
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: .gbnf),
      #"start ::= "" | "a""#
    )
  }
}
