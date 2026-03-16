import CustomDump
import Testing
import StructuredCFG

@Suite
struct `GrammarBuilder tests` {
  @Test
  func `Builds Empty Grammar`() {
    let grammar = Grammar()
    expectNoDifference(grammar.startingSymbol, .root)
    expectNoDifference(grammar, Grammar(Rule(.root) { EmptyExpression() }))
  }

  @Test
  func `Builds Grammar From Productions`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") { "value" }
      Rule("term") { Ref("expression") }
    }

    expectNoDifference(grammar.startingSymbol, "expression")
    expectNoDifference(grammar, Grammar(startingSymbol: "expression") {
      Rule("expression") { "value" }
      Rule("term") { Ref("expression") }
    })
  }

  @Test
  func `Builds Grammar From Nested Grammar Fragments`() {
    let fragment = Grammar(Rule("expression") { "value" })

    let grammar = Grammar(startingSymbol: "expression") {
      fragment
      Rule("term") { Ref("expression") }
    }

    expectNoDifference(grammar, Grammar(startingSymbol: "expression") {
      Rule("expression") { "value" }
      Rule("term") { Ref("expression") }
    })
  }

  @Test
  func `Duplicate Identifiers Use Last Wins Semantics`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") { "first" }
      Rule("term") { "value" }
      Rule("expression") { "second" }
    }

    expectNoDifference(grammar, Grammar(startingSymbol: "expression") {
      Rule("expression") { "second" }
      Rule("term") { "value" }
    })
  }
}
