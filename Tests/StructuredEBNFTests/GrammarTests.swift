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

  @Test
  func `Replacing Production Overwrites Existing Production Without Mutating Original`() {
    let grammar = Grammar {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    }

    let replaced = grammar.replacingProduction(
      named: "expression",
      with: "updated"
    )

    expectNoDifference(
      Array(grammar.productions),
      [
        Production("expression") { "value" },
        Production("term", Ref("expression"))
      ]
    )
    expectNoDifference(
      Array(replaced.productions),
      [
        Production("expression") { "updated" },
        Production("term", Ref("expression"))
      ]
    )
  }

  @Test
  func `Replacing Production Inserts Missing Production At End`() {
    let grammar = Grammar {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    }

    let replaced = grammar.replacingProduction(named: "factor") {
      Ref("term")
    }

    expectNoDifference(
      Array(replaced.productions),
      [
        Production("expression") { "value" },
        Production("term") { Ref("expression") },
        Production("factor") { Ref("term") }
      ]
    )
  }

  @Test
  func `Replacing Production Uses Named Identifier For Inserted Production`() {
    let grammar = Grammar()

    let replaced = grammar.replacingProduction(named: "factor", with: "value")

    expectNoDifference(replaced["factor"]?.identifier, "factor")
    expectNoDifference(Array(replaced.productions), [Production("factor") { "value" }])
  }

  @Test
  func `Appending Production Returns New Grammar Without Mutating Original`() {
    let grammar = Grammar {
      Production("expression") { "value" }
    }

    let appended = grammar.appending(Production("term") { Ref("expression") })

    expectNoDifference(
      Array(grammar.productions),
      [
        Production("expression") { "value" }
      ]
    )
    expectNoDifference(
      Array(appended.productions),
      [
        Production("expression") { "value" },
        Production("term") { Ref("expression") }
      ]
    )
  }

  @Test
  func `Append Inserts Missing Production At End`() {
    var grammar = Grammar {
      Production("expression") { "value" }
    }

    grammar.append(Production("term") { Ref("expression") })

    expectNoDifference(
      Array(grammar.productions),
      [
        Production("expression") { "value" },
        Production("term") { Ref("expression") }
      ]
    )
  }

  @Test
  func `Append Overwrites Existing Production Using Production Identifier`() {
    var grammar = Grammar {
      Production("expression") { "first" }
      Production("term") { "value" }
    }

    grammar.append(Production("expression") { "second" })

    expectNoDifference(
      Array(grammar.productions),
      [
        Production("expression") { "second" },
        Production("term") { "value" }
      ]
    )
  }
}
