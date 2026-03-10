import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `GrammarBuilder tests` {
  @Test
  func `Builds Empty Grammar`() {
    let grammar = Grammar {}
    expectNoDifference(Array(grammar.productions), [Production]())
  }

  @Test
  func `Builds Grammar From Productions`() {
    let grammar = Grammar {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    }

    expectNoDifference(
      Array(grammar.productions),
      [
        Production("expression") { "value" },
        Production("term", Ref("expression"))
      ]
    )
  }

  @Test
  func `Builds Grammar From Nested Grammar Fragments`() {
    let fragment = Grammar {
      Production("expression") { "value" }
    }

    let grammar = Grammar {
      fragment
      Production("term") { Ref("expression") }
    }

    expectNoDifference(
      Array(grammar.productions),
      [
        Production("expression") { "value" },
        Production("term", Ref("expression"))
      ]
    )
  }

  @Test
  func `Duplicate Identifiers Use Last Wins Semantics`() {
    let grammar = Grammar {
      Production("expression") { "first" }
      Production("term") { "value" }
      Production("expression") { "second" }
    }

    expectNoDifference(
      Array(grammar.productions),
      [
        Production("expression") { "second" },
        Production("term") { "value" }
      ]
    )
  }
}
