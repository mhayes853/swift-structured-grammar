import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `GrammarBuilder tests` {
  @Test
  func `Builds Empty Grammar`() {
    let grammar = Grammar()
    expectNoDifference(grammar.startingSymbol, .root)
    expectNoDifference(grammar, Grammar(Production(.root) { EmptyExpression() }))
  }

  @Test
  func `Builds Grammar From Productions`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    }

    expectNoDifference(grammar.startingSymbol, "expression")
    expectNoDifference(grammar, Grammar(startingSymbol: "expression") {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    })
  }

  @Test
  func `Builds Grammar From Nested Grammar Fragments`() {
    let fragment = Grammar(Production("expression") { "value" })

    let grammar = Grammar(startingSymbol: "expression") {
      fragment
      Production("term") { Ref("expression") }
    }

    expectNoDifference(grammar, Grammar(startingSymbol: "expression") {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    })
  }

  @Test
  func `Duplicate Identifiers Use Last Wins Semantics`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Production("expression") { "first" }
      Production("term") { "value" }
      Production("expression") { "second" }
    }

    expectNoDifference(grammar, Grammar(startingSymbol: "expression") {
      Production("expression") { "second" }
      Production("term") { "value" }
    })
  }
}
