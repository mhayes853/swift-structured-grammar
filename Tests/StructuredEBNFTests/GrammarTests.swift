import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `Grammar tests` {
  @Test
  func `Productions Preserves Order And Supports Indexing`() {
    let grammar = Grammar {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    }

    expectNoDifference(grammar.productions.count, 2)
    expectNoDifference(grammar.productions.startIndex, 0)
    expectNoDifference(grammar.productions[0], Production("expression") { "value" })
    expectNoDifference(grammar.productions[1], Production("term", Ref("expression")))
  }

  @Test
  func `Productions Supports Identifier Subscript Reads`() {
    let grammar = Grammar {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    }

    expectNoDifference(grammar.productions["expression"], Production("expression") { "value" })
    expectNoDifference(grammar.productions["term"], Production("term", Ref("expression")))
    expectNoDifference(grammar.productions["factor"], nil)
  }
}
