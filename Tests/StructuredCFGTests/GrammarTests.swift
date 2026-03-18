import CustomDump
import Testing
import StructuredCFG

@Suite
struct `Grammar tests` {
  @Test
  func `Productions Preserves Order And Supports Indexing`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") { "value" }
      Rule("term") { Ref("expression") }
    }

    expectNoDifference(grammar.rules.count, 2)
    expectNoDifference(grammar.rules.startIndex, 0)
    expectNoDifference(grammar[0], Rule("expression") { "value" })
    expectNoDifference(grammar[1], Rule("term", Ref("expression")))
    expectNoDifference(grammar.rules[0], Rule("expression") { "value" })
    expectNoDifference(grammar.rules[1], Rule("term", Ref("expression")))
  }

  @Test
  func `Sequence Initializer Builds Grammar With Last Wins Semantics`() {
    let grammar = Grammar(startingSymbol: "expression", [
      Rule("expression") { "first" },
      Rule("term") { "value" },
      Rule("expression") { "second" }
    ])

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "second" }
        Rule("term") { "value" }
      }
    )
  }

  @Test
  func `Productions Supports Identifier Subscript Reads`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") { "value" }
      Rule("term") { Ref("expression") }
    }

    expectNoDifference(grammar.rules["expression"], Rule("expression") { "value" })
    expectNoDifference(grammar.rules["term"], Rule("term", Ref("expression")))
    expectNoDifference(grammar.rules["factor"], nil)
    expectNoDifference(grammar["expression"], Rule("expression") { "value" })
    expectNoDifference(grammar["term"], Rule("term", Ref("expression")))
    expectNoDifference(grammar["factor"], nil)
  }

  @Test
  func `Contains Production Reports Presence By Identifier`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") { "value" }
      Rule("term") { Ref("expression") }
    }

    expectNoDifference(grammar.containsRule(for: "expression"), true)
    expectNoDifference(grammar.containsRule(for: "term"), true)
    expectNoDifference(grammar.containsRule(for: "factor"), false)
  }

  @Test
  func `Mutating Starting Identifier To Existing Production Reorders Start`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") { "value" }
      Rule("term") { Ref("expression") }
    }

    grammar.startingSymbol = "term"

    expectNoDifference(grammar.startingSymbol, "term")
    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "term") {
        Rule("expression") { "value" }
        Rule("term") { Ref("expression") }
      }
    )
  }

  @Test
  func `Mutating Starting Identifier To Missing Production Inserts Empty Production`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") { "value" }
      Rule("term") { Ref("expression") }
    }

    grammar.startingSymbol = "factor"

    expectNoDifference(grammar.startingSymbol, "factor")
    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "factor") {
        Rule("expression") { "value" }
        Rule("term") { Ref("expression") }
      }
    )
    expectNoDifference(grammar["factor"], Rule("factor") { Epsilon() })
  }

  @Test
  func `Remove Production Identifier Removes Matching Production`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") { "value" }
      Rule("term") { Ref("expression") }
      Rule("factor") { Ref("term") }
    }

    grammar.removeRule(for: "term")

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "value" }
        Rule("factor") { Ref("term") }
      }
    )
    expectNoDifference(grammar.containsRule(for: "term"), false)
  }

  @Test
  func `Remove Production Identifier Is No Op For Missing Identifier`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") { "value" }
      Rule("term") { Ref("expression") }
    }

    grammar.removeRule(for: "factor")

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "value" }
        Rule("term") { Ref("expression") }
      }
    )
  }

  @Test
  func `Remove All Clears Grammar`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") { "value" }
      Rule("term") { Ref("expression") }
    }

    grammar.removeAll()

    expectNoDifference(grammar, Grammar(startingSymbol: "expression", [Rule("expression") { Epsilon() }]))
    expectNoDifference(grammar.containsRule(for: "expression"), true)
    expectNoDifference(grammar.containsRule(for: "term"), false)
  }

  @Test
  func `Remove All Where Removes Matching Productions And Preserves Remaining Order`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") { "value" }
      Rule("term") { Ref("expression") }
      Rule("factor") { Ref("term") }
    }

    grammar.removeAll { production in
      production.symbol == "expression" || production.symbol == "factor"
    }

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Rule("expression") { Epsilon() }
        Rule("term") { Ref("expression") }
      }
    )
  }

  @Test
  func `Replacing Production Overwrites Existing Production Without Mutating Original`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") { "value" }
      Rule("term") { Ref("expression") }
    }

    let replaced = grammar.replacingRule(
      for: "expression",
      with: "updated"
    )

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "value" }
        Rule("term", Ref("expression"))
      }
    )
    expectNoDifference(
      replaced,
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "updated" }
        Rule("term", Ref("expression"))
      }
    )
  }

  @Test
  func `Replacing Production Inserts Missing Production At End`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") { "value" }
      Rule("term") { Ref("expression") }
    }

    let replaced = grammar.replacingRule(for: "factor") {
      Ref("term")
    }

    expectNoDifference(
      replaced,
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "value" }
        Rule("term") { Ref("expression") }
        Rule("factor") { Ref("term") }
      }
    )
  }

  @Test
  func `Replacing Production Uses Named Identifier For Inserted Production`() {
    let grammar = Grammar()

    let replaced = grammar.replacingRule(for: "factor", with: "value")

    expectNoDifference(replaced["factor"]?.symbol, "factor")
    expectNoDifference(
      replaced,
      Grammar(startingSymbol: .root) {
        Rule(.root) { Epsilon() }
        Rule("factor") { "value" }
      }
    )
  }

  @Test
  func `Appending Production Returns New Grammar Without Mutating Original`() {
    let grammar = Grammar(Rule("expression") { "value" })

    let appended = grammar.appending(Rule("term") { Ref("expression") })

    expectNoDifference(
      grammar,
      Grammar(Rule("expression") { "value" })
    )
    expectNoDifference(
      appended,
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "value" }
        Rule("term") { Ref("expression") }
      }
    )
  }

  @Test
  func `Append Inserts Missing Production At End`() {
    var grammar = Grammar(Rule("expression") { "value" })

    grammar.append(Rule("term") { Ref("expression") })

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "value" }
        Rule("term") { Ref("expression") }
      }
    )
  }

  @Test
  func `Append Overwrites Existing Production Using Production Identifier`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") { "first" }
      Rule("term") { "value" }
    }

    grammar.append(Rule("expression") { "second" })

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "second" }
        Rule("term") { "value" }
      }
    )
  }

  @Test
  func `Appending Contents Of Returns New Grammar Without Mutating Original`() {
    let grammar = Grammar(Rule("expression") { "value" })

    let appended = grammar.appending(contentsOf: [
      Rule("term") { Ref("expression") },
      Rule("factor") { Ref("term") }
    ])

    expectNoDifference(
      grammar,
      Grammar(Rule("expression") { "value" })
    )
    expectNoDifference(
      appended,
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "value" }
        Rule("term") { Ref("expression") }
        Rule("factor") { Ref("term") }
      }
    )
  }

  @Test
  func `Append Contents Of Applies Last Wins Semantics In Sequence Order`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") { "first" }
      Rule("term") { "value" }
    }

    grammar.append(contentsOf: [
      Rule("factor") { Ref("term") },
      Rule("expression") { "second" }
    ])

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "second" }
        Rule("term") { "value" }
        Rule("factor") { Ref("term") }
      }
    )
  }

  @Test
  func `Merge Overwrites Existing Productions And Appends New Ones`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") { "first" }
      Rule("term") { "value" }
    }
    let other = Grammar(startingSymbol: "factor") {
      Rule("factor") { Ref("term") }
      Rule("expression") { "second" }
    }

    grammar.merge(other)

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "second" }
        Rule("term") { "value" }
        Rule("factor") { Ref("term") }
      }
    )
  }

  @Test
  func `Merge Preserves Original Slot Of Overwritten Production`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") { "first" }
      Rule("term") { "value" }
      Rule("factor") { Ref("term") }
    }
    let other = Grammar(Rule("term") { Ref("expression") })

    grammar.merge(other)

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Rule("expression") { "first" }
        Rule("term") { Ref("expression") }
        Rule("factor") { Ref("term") }
      }
    )
  }

  @Test
  func `Homomorph Replaces Matching Terminal Across Grammar`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") {
        "+"
        Ref("term")
      }
      Rule("term") {
        "+"
      }
    }

    grammar.homomorph("+", to: "-")

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Rule("expression") {
          "-"
          Ref("term")
        }
        Rule("term") {
          "-"
        }
      }
    )
  }

  @Test
  func `Homomorph Map Leaves Unmatched Terminals Unchanged`() {
    let production = Rule("expression") {
      Choice {
        "+"
        "*"
      }
    }
    let grammar = Grammar(production)

    let homomorphed = grammar.homomorphMapped { terminal in
      if terminal == "+" {
        return "-"
      } else {
        return nil
      }
    }
    let expected = Grammar(Rule("expression") {
      Choice {
        "-"
        "*"
      }
    })

    expectNoDifference(homomorphed, expected)
  }

  @Test
  func `Homomorph Map Rewrites Nested Expressions`() {
    let production = Rule("expression") {
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
    let grammar = Grammar(production)

    let homomorphed = grammar.homomorphMapped { terminal in
      if terminal == "+" {
        return "-"
      } else {
        return nil
      }
    }
    let expected = Grammar(Rule("expression") {
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
    })

    expectNoDifference(homomorphed, expected)
  }

  @Test
  func `Homomorph Map Handles Empty ConcatanateExpressions Ref And Terminal Cases`() {
    let grammar = Grammar(startingSymbol: "epsilon") {
      Rule("epsilon") {
        Epsilon()
      }
      Rule("expression") {
        ConcatenateExpressions {
          Ref("identifier")
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
      Grammar(startingSymbol: "epsilon") {
        Rule("epsilon") {
          Epsilon()
        }
        Rule("expression") {
          ConcatenateExpressions {
            Ref("identifier")
            Ref("epsilon")
            "b"
        }
      }
      }
    )
  }

  @Test
  func `Reversed Concatenation Element Order`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") {
        ConcatenateExpressions {
          "a"
          "b"
          "c"
        }
      }
    }

    let reversed = grammar.reversed()

    expectNoDifference(
      reversed,
      Grammar(startingSymbol: "expression") {
        Rule("expression") {
          ConcatenateExpressions {
            "c"
            "b"
            "a"
          }
        }
      }
    )
  }

  @Test
  func `Reversed Reverses Choice Alternatives Contents`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") {
        Choice {
          ConcatenateExpressions {
            "a"
            "b"
          }
          ConcatenateExpressions {
            "c"
            "d"
          }
        }
      }
    }

    let reversed = grammar.reversed()

    expectNoDifference(
      reversed,
      Grammar(startingSymbol: "expression") {
        Rule("expression") {
          Choice {
            ConcatenateExpressions {
              "b"
              "a"
            }
            ConcatenateExpressions {
              "d"
              "c"
            }
          }
        }
      }
    )
  }

  @Test
  func `Reversed Reverses Optional Expression Contents`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") {
        OptionalExpression {
          ConcatenateExpressions {
            "a"
            "b"
          }
        }
      }
    }

    let reversed = grammar.reversed()

    expectNoDifference(
      reversed,
      Grammar(startingSymbol: "expression") {
        Rule("expression") {
          OptionalExpression {
            ConcatenateExpressions {
              "b"
              "a"
            }
          }
        }
      }
    )
  }

  @Test
  func `Reversed Reverses ZeroOrMore Expression Contents`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") {
        ZeroOrMore {
          ConcatenateExpressions {
            "a"
            "b"
          }
        }
      }
    }

    let reversed = grammar.reversed()

    expectNoDifference(
      reversed,
      Grammar(startingSymbol: "expression") {
        Rule("expression") {
          ZeroOrMore {
            ConcatenateExpressions {
              "b"
              "a"
            }
          }
        }
      }
    )
  }

  @Test
  func `Reversed Reverses Group Expression Contents`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") {
        Group {
          ConcatenateExpressions {
            "a"
            "b"
          }
        }
      }
    }

    let reversed = grammar.reversed()

    expectNoDifference(
      reversed,
      Grammar(startingSymbol: "expression") {
        Rule("expression") {
          Group {
            ConcatenateExpressions {
              "b"
              "a"
            }
          }
        }
      }
    )
  }

  @Test
  func `Reversed Omits Unreachable Productions`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") {
        Ref("term")
      }
      Rule("term") {
        Ref("factor")
      }
      Rule("factor") {
        "value"
      }
      Rule("dead") {
        "unreachable"
      }
    }

    let reversed = grammar.reversed()

    expectNoDifference(
      reversed,
      Grammar(startingSymbol: "expression") {
        Rule("expression") {
          Ref("term")
        }
        Rule("term") {
          Ref("factor")
        }
        Rule("factor") {
          "value"
        }
      }
    )
    expectNoDifference(reversed.containsRule(for: "dead"), false)
  }

  @Test
  func `Mutating Reverse Updates Grammar`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") {
        ConcatenateExpressions {
          "a"
          "b"
        }
      }
    }

    grammar.reverse()

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Rule("expression") {
          ConcatenateExpressions {
            "b"
            "a"
          }
        }
      }
    )
  }
}
