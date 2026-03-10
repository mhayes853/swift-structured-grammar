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
    expectNoDifference(grammar[0], Production("expression") { "value" })
    expectNoDifference(grammar[1], Production("term", Ref("expression")))
    expectNoDifference(grammar.productions[0], Production("expression") { "value" })
    expectNoDifference(grammar.productions[1], Production("term", Ref("expression")))
  }

  @Test
  func `Sequence Initializer Builds Grammar With Last Wins Semantics`() {
    let grammar = Grammar([
      Production("expression") { "first" },
      Production("term") { "value" },
      Production("expression") { "second" }
    ])

    expectNoDifference(
      grammar,
      Grammar {
        Production("expression") { "second" }
        Production("term") { "value" }
      }
    )
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
    expectNoDifference(grammar["expression"], Production("expression") { "value" })
    expectNoDifference(grammar["term"], Production("term", Ref("expression")))
    expectNoDifference(grammar["factor"], nil)
  }

  @Test
  func `Contains Production Reports Presence By Identifier`() {
    let grammar = Grammar {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    }

    expectNoDifference(grammar.containsProduction(identifier: "expression"), true)
    expectNoDifference(grammar.containsProduction(identifier: "term"), true)
    expectNoDifference(grammar.containsProduction(identifier: "factor"), false)
  }

  @Test
  func `Remove Production Identifier Removes Matching Production`() {
    var grammar = Grammar {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
      Production("factor") { Ref("term") }
    }

    grammar.removeProduction(identifier: "term")

    expectNoDifference(
      grammar,
      Grammar {
        Production("expression") { "value" }
        Production("factor") { Ref("term") }
      }
    )
    expectNoDifference(grammar.containsProduction(identifier: "term"), false)
  }

  @Test
  func `Remove Production Identifier Is No Op For Missing Identifier`() {
    var grammar = Grammar {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    }

    grammar.removeProduction(identifier: "factor")

    expectNoDifference(
      grammar,
      Grammar {
        Production("expression") { "value" }
        Production("term") { Ref("expression") }
      }
    )
  }

  @Test
  func `Remove All Clears Grammar`() {
    var grammar = Grammar {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    }

    grammar.removeAll()

    expectNoDifference(grammar, Grammar())
    expectNoDifference(grammar.containsProduction(identifier: "expression"), false)
    expectNoDifference(grammar.containsProduction(identifier: "term"), false)
  }

  @Test
  func `Remove All Where Removes Matching Productions And Preserves Remaining Order`() {
    var grammar = Grammar {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
      Production("factor") { Ref("term") }
    }

    grammar.removeAll { production in
      production.identifier == "expression" || production.identifier == "factor"
    }

    expectNoDifference(
      grammar,
      Grammar {
        Production("term") { Ref("expression") }
      }
    )
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
      grammar,
      Grammar {
        Production("expression") { "value" }
        Production("term", Ref("expression"))
      }
    )
    expectNoDifference(
      replaced,
      Grammar {
        Production("expression") { "updated" }
        Production("term", Ref("expression"))
      }
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
      replaced,
      Grammar {
        Production("expression") { "value" }
        Production("term") { Ref("expression") }
        Production("factor") { Ref("term") }
      }
    )
  }

  @Test
  func `Replacing Production Uses Named Identifier For Inserted Production`() {
    let grammar = Grammar()

    let replaced = grammar.replacingProduction(named: "factor", with: "value")

    expectNoDifference(replaced["factor"]?.identifier, "factor")
    expectNoDifference(replaced, Grammar { Production("factor") { "value" } })
  }

  @Test
  func `Appending Production Returns New Grammar Without Mutating Original`() {
    let grammar = Grammar {
      Production("expression") { "value" }
    }

    let appended = grammar.appending(Production("term") { Ref("expression") })

    expectNoDifference(
      grammar,
      Grammar {
        Production("expression") { "value" }
      }
    )
    expectNoDifference(
      appended,
      Grammar {
        Production("expression") { "value" }
        Production("term") { Ref("expression") }
      }
    )
  }

  @Test
  func `Append Inserts Missing Production At End`() {
    var grammar = Grammar {
      Production("expression") { "value" }
    }

    grammar.append(Production("term") { Ref("expression") })

    expectNoDifference(
      grammar,
      Grammar {
        Production("expression") { "value" }
        Production("term") { Ref("expression") }
      }
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
      grammar,
      Grammar {
        Production("expression") { "second" }
        Production("term") { "value" }
      }
    )
  }

  @Test
  func `Appending Contents Of Returns New Grammar Without Mutating Original`() {
    let grammar = Grammar {
      Production("expression") { "value" }
    }

    let appended = grammar.appending(contentsOf: [
      Production("term") { Ref("expression") },
      Production("factor") { Ref("term") }
    ])

    expectNoDifference(
      grammar,
      Grammar {
        Production("expression") { "value" }
      }
    )
    expectNoDifference(
      appended,
      Grammar {
        Production("expression") { "value" }
        Production("term") { Ref("expression") }
        Production("factor") { Ref("term") }
      }
    )
  }

  @Test
  func `Append Contents Of Applies Last Wins Semantics In Sequence Order`() {
    var grammar = Grammar {
      Production("expression") { "first" }
      Production("term") { "value" }
    }

    grammar.append(contentsOf: [
      Production("factor") { Ref("term") },
      Production("expression") { "second" }
    ])

    expectNoDifference(
      grammar,
      Grammar {
        Production("expression") { "second" }
        Production("term") { "value" }
        Production("factor") { Ref("term") }
      }
    )
  }

  @Test
  func `Merge Overwrites Existing Productions And Appends New Ones`() {
    var grammar = Grammar {
      Production("expression") { "first" }
      Production("term") { "value" }
    }
    let other = Grammar {
      Production("factor") { Ref("term") }
      Production("expression") { "second" }
    }

    grammar.merge(other)

    expectNoDifference(
      grammar,
      Grammar {
        Production("expression") { "second" }
        Production("term") { "value" }
        Production("factor") { Ref("term") }
      }
    )
  }

  @Test
  func `Merge Preserves Original Slot Of Overwritten Production`() {
    var grammar = Grammar {
      Production("expression") { "first" }
      Production("term") { "value" }
      Production("factor") { Ref("term") }
    }
    let other = Grammar {
      Production("term") { Ref("expression") }
    }

    grammar.merge(other)

    expectNoDifference(
      grammar,
      Grammar {
        Production("expression") { "first" }
        Production("term") { Ref("expression") }
        Production("factor") { Ref("term") }
      }
    )
  }

  @Test
  func `Homomorph Replaces Matching Terminal Across Grammar`() {
    var grammar = Grammar {
      Production("expression") {
        "+"
        Ref("term")
      }
      Production("term") {
        "+"
      }
    }

    grammar.homomorph("+", to: "-")

    expectNoDifference(
      grammar,
      Grammar {
        Production("expression") {
          "-"
          Ref("term")
        }
        Production("term") {
          "-"
        }
      }
    )
  }

  @Test
  func `Homomorph Map Leaves Unmatched Terminals Unchanged`() {
    let grammar = Grammar {
      Production("expression") {
        Choice {
          "+"
          "*"
        }
      }
    }

    let homomorphed = grammar.homomorphMapped { terminal in
      if terminal == "+" {
        "-"
      } else {
        nil
      }
    }

    expectNoDifference(
      homomorphed,
      Grammar {
        Production("expression") {
          Choice {
            "-"
            "*"
          }
        }
      }
    )
  }

  @Test
  func `Homomorph Map Rewrites Nested Expressions`() {
    let grammar = Grammar {
      Production("expression") {
        OptionalExpression {
          "+"
        }
        ZeroOrMore {
          Group {
            Choice {
              "+"
              "*"
            }
          }
        }
      }
    }

    let homomorphed = grammar.homomorphMapped { terminal in
      if terminal == "+" {
        "-"
      } else {
        nil
      }
    }

    expectNoDifference(
      homomorphed,
      Grammar {
        Production("expression") {
          OptionalExpression {
            "-"
          }
          ZeroOrMore {
            Group {
              Choice {
                "-"
                "*"
              }
            }
          }
        }
      }
    )
  }

  @Test
  func `Homomorph Map Handles Empty ConcatanateExpressions Ref Special And Terminal Cases`() {
    let grammar = Grammar {
      Production("epsilon") {
        EmptyExpression()
      }
      Production("expression") {
        ConcatanateExpressions {
          Special("identifier")
          Ref("epsilon")
          "a"
        }
      }
    }

    let homomorphed = grammar.homomorphMapped { terminal in
      if terminal == "a" {
        "b"
      } else {
        nil
      }
    }

    expectNoDifference(
      homomorphed,
      Grammar {
        Production("epsilon") {
          EmptyExpression()
        }
        Production("expression") {
          ConcatanateExpressions {
            Special("identifier")
            Ref("epsilon")
            "b"
          }
        }
      }
    )
  }

  @Test
  func `Formats Non Trivial Grammar Exactly`() {
    let grammar = Grammar {
      Production("sign") {
        OptionalExpression {
          Choice {
            "+"
            "-"
          }
        }
      }

      Production("term") {
        Choice {
          Ref("number")
          Group {
            "("
            Ref("expression")
            ")"
          }
          Special("identifier")
        }
      }

      Production("expression") {
        Ref("sign")
        Ref("term")
        ZeroOrMore {
          ConcatanateExpressions {
            Group {
              Choice {
                "+"
                "-"
              }
            }
            Ref("term")
          }
        }
      }
    }

    expectNoDifference(
      grammar.formatted(),
      """
      sign = ["+" | "-"] ;
      term = number | ("(", expression, ")") | ? identifier ? ;
      expression = sign, term, {("+" | "-"), term} ;
      """
    )
  }
}
