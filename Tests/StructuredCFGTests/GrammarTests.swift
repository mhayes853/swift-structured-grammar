import CustomDump
import Testing
import StructuredCFG

@Suite
struct `Grammar tests` {
  @Test
  func `Productions Preserves Order And Supports Indexing`() {
    let grammar = Grammar(startingSymbol: "expression") {
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
    let grammar = Grammar(startingSymbol: "expression", [
      Production("expression") { "first" },
      Production("term") { "value" },
      Production("expression") { "second" }
    ])

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Production("expression") { "second" }
        Production("term") { "value" }
      }
    )
  }

  @Test
  func `Productions Supports Identifier Subscript Reads`() {
    let grammar = Grammar(startingSymbol: "expression") {
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
    let grammar = Grammar(startingSymbol: "expression") {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    }

    expectNoDifference(grammar.containsProduction(for: "expression"), true)
    expectNoDifference(grammar.containsProduction(for: "term"), true)
    expectNoDifference(grammar.containsProduction(for: "factor"), false)
  }

  @Test
  func `Mutating Starting Identifier To Existing Production Reorders Start`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    }

    grammar.startingSymbol = "term"

    expectNoDifference(grammar.startingSymbol, "term")
    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "term") {
        Production("expression") { "value" }
        Production("term") { Ref("expression") }
      }
    )
  }

  @Test
  func `Mutating Starting Identifier To Missing Production Inserts Empty Production`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    }

    grammar.startingSymbol = "factor"

    expectNoDifference(grammar.startingSymbol, "factor")
    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "factor") {
        Production("expression") { "value" }
        Production("term") { Ref("expression") }
      }
    )
    expectNoDifference(grammar["factor"], Production("factor") { EmptyExpression() })
  }

  @Test
  func `Remove Production Identifier Removes Matching Production`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
      Production("factor") { Ref("term") }
    }

    grammar.removeProduction(for: "term")

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Production("expression") { "value" }
        Production("factor") { Ref("term") }
      }
    )
    expectNoDifference(grammar.containsProduction(for: "term"), false)
  }

  @Test
  func `Remove Production Identifier Is No Op For Missing Identifier`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    }

    grammar.removeProduction(for: "factor")

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Production("expression") { "value" }
        Production("term") { Ref("expression") }
      }
    )
  }

  @Test
  func `Remove All Clears Grammar`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    }

    grammar.removeAll()

    expectNoDifference(grammar, Grammar(startingSymbol: "expression", [Production("expression") { EmptyExpression() }]))
    expectNoDifference(grammar.containsProduction(for: "expression"), true)
    expectNoDifference(grammar.containsProduction(for: "term"), false)
  }

  @Test
  func `Remove All Where Removes Matching Productions And Preserves Remaining Order`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
      Production("factor") { Ref("term") }
    }

    grammar.removeAll { production in
      production.symbol == "expression" || production.symbol == "factor"
    }

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Production("expression") { EmptyExpression() }
        Production("term") { Ref("expression") }
      }
    )
  }

  @Test
  func `Replacing Production Overwrites Existing Production Without Mutating Original`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    }

    let replaced = grammar.replacingProduction(
      for: "expression",
      with: "updated"
    )

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Production("expression") { "value" }
        Production("term", Ref("expression"))
      }
    )
    expectNoDifference(
      replaced,
      Grammar(startingSymbol: "expression") {
        Production("expression") { "updated" }
        Production("term", Ref("expression"))
      }
    )
  }

  @Test
  func `Replacing Production Inserts Missing Production At End`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Production("expression") { "value" }
      Production("term") { Ref("expression") }
    }

    let replaced = grammar.replacingProduction(for: "factor") {
      Ref("term")
    }

    expectNoDifference(
      replaced,
      Grammar(startingSymbol: "expression") {
        Production("expression") { "value" }
        Production("term") { Ref("expression") }
        Production("factor") { Ref("term") }
      }
    )
  }

  @Test
  func `Replacing Production Uses Named Identifier For Inserted Production`() {
    let grammar = Grammar()

    let replaced = grammar.replacingProduction(for: "factor", with: "value")

    expectNoDifference(replaced["factor"]?.symbol, "factor")
    expectNoDifference(
      replaced,
      Grammar(startingSymbol: .root) {
        Production(.root) { EmptyExpression() }
        Production("factor") { "value" }
      }
    )
  }

  @Test
  func `Appending Production Returns New Grammar Without Mutating Original`() {
    let grammar = Grammar(Production("expression") { "value" })

    let appended = grammar.appending(Production("term") { Ref("expression") })

    expectNoDifference(
      grammar,
      Grammar(Production("expression") { "value" })
    )
    expectNoDifference(
      appended,
      Grammar(startingSymbol: "expression") {
        Production("expression") { "value" }
        Production("term") { Ref("expression") }
      }
    )
  }

  @Test
  func `Append Inserts Missing Production At End`() {
    var grammar = Grammar(Production("expression") { "value" })

    grammar.append(Production("term") { Ref("expression") })

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Production("expression") { "value" }
        Production("term") { Ref("expression") }
      }
    )
  }

  @Test
  func `Append Overwrites Existing Production Using Production Identifier`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Production("expression") { "first" }
      Production("term") { "value" }
    }

    grammar.append(Production("expression") { "second" })

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Production("expression") { "second" }
        Production("term") { "value" }
      }
    )
  }

  @Test
  func `Appending Contents Of Returns New Grammar Without Mutating Original`() {
    let grammar = Grammar(Production("expression") { "value" })

    let appended = grammar.appending(contentsOf: [
      Production("term") { Ref("expression") },
      Production("factor") { Ref("term") }
    ])

    expectNoDifference(
      grammar,
      Grammar(Production("expression") { "value" })
    )
    expectNoDifference(
      appended,
      Grammar(startingSymbol: "expression") {
        Production("expression") { "value" }
        Production("term") { Ref("expression") }
        Production("factor") { Ref("term") }
      }
    )
  }

  @Test
  func `Append Contents Of Applies Last Wins Semantics In Sequence Order`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Production("expression") { "first" }
      Production("term") { "value" }
    }

    grammar.append(contentsOf: [
      Production("factor") { Ref("term") },
      Production("expression") { "second" }
    ])

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Production("expression") { "second" }
        Production("term") { "value" }
        Production("factor") { Ref("term") }
      }
    )
  }

  @Test
  func `Merge Overwrites Existing Productions And Appends New Ones`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Production("expression") { "first" }
      Production("term") { "value" }
    }
    let other = Grammar(startingSymbol: "factor") {
      Production("factor") { Ref("term") }
      Production("expression") { "second" }
    }

    grammar.merge(other)

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Production("expression") { "second" }
        Production("term") { "value" }
        Production("factor") { Ref("term") }
      }
    )
  }

  @Test
  func `Merge Preserves Original Slot Of Overwritten Production`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Production("expression") { "first" }
      Production("term") { "value" }
      Production("factor") { Ref("term") }
    }
    let other = Grammar(Production("term") { Ref("expression") })

    grammar.merge(other)

    expectNoDifference(
      grammar,
      Grammar(startingSymbol: "expression") {
        Production("expression") { "first" }
        Production("term") { Ref("expression") }
        Production("factor") { Ref("term") }
      }
    )
  }

  @Test
  func `Homomorph Replaces Matching Terminal Across Grammar`() {
    var grammar = Grammar(startingSymbol: "expression") {
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
      Grammar(startingSymbol: "expression") {
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
    let production = Production("expression") {
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
    let expected = Grammar(Production("expression") {
      Choice {
        "-"
        "*"
      }
    })

    expectNoDifference(homomorphed, expected)
  }

  @Test
  func `Homomorph Map Rewrites Nested Expressions`() {
    let production = Production("expression") {
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
    let expected = Grammar(Production("expression") {
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
      Production("epsilon") {
        EmptyExpression()
      }
      Production("expression") {
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
        Production("epsilon") {
          EmptyExpression()
        }
        Production("expression") {
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
  func `Formats Non Trivial Grammar Exactly`() {
    let grammar = Grammar(startingSymbol: "sign") {
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
          "identifier"
        }
      }

      Production("expression") {
        Ref("sign")
        Ref("term")
        ZeroOrMore {
          ConcatenateExpressions {
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
      grammar.formatted(with: .w3cEbnf),
      """
      sign ::= ("+" | "-")?
      term ::= number | ("(" expression ")") | "identifier"
      expression ::= sign term (("+" | "-") term)*
      """
    )
  }

  @Test
  func `Formatting Omits Empty Productions Entirely`() {
    let grammar = Grammar(startingSymbol: "padding") {
      Production("padding") {
        EmptyExpression()
      }
    }

    expectNoDifference(grammar.formatted(with: .w3cEbnf), "")
  }

  @Test
  func `Formatting Concatenation Drops Empty Members`() {
    let grammar = Grammar(Production("start") {
      ConcatenateExpressions {
        EmptyExpression()
        "a"
        Ref("target")
      }
    })

    expectNoDifference(grammar.formatted(with: .w3cEbnf), #"start ::= "a" target"#)
  }

  @Test
  func `Formatting Choice Drops Empty Alternatives`() {
    let grammar = Grammar(Production("start") {
      Choice {
        EmptyExpression()
        "a"
        "b"
      }
    })

    expectNoDifference(grammar.formatted(with: .w3cEbnf), #"start ::= "a" | "b""#)
  }

  @Test
  func `Formatting Optional Of Empty Disappears`() {
    let grammar = Grammar(Production("start") {
      OptionalExpression {
        EmptyExpression()
      }
    })

    expectNoDifference(grammar.formatted(with: .w3cEbnf), "")
  }

  @Test
  func `Formatting Zero Or More Of Empty Disappears`() {
    let grammar = Grammar(Production("start") {
      ZeroOrMore {
        EmptyExpression()
      }
    })

    expectNoDifference(grammar.formatted(with: .w3cEbnf), "")
  }

  @Test
  func `Formatting Group Of Empty Disappears`() {
    let grammar = Grammar(Production("start") {
      Group {
        EmptyExpression()
      }
    })

    expectNoDifference(grammar.formatted(with: .w3cEbnf), "")
  }

  @Test
  func `Formatting One Or More Uses Native W3C Syntax`() {
    let grammar = Grammar(Production("start") {
      OneOrMore {
        Choice {
          "a"
          "b"
        }
      }
    })

    expectNoDifference(grammar.formatted(with: .w3cEbnf), #"start ::= ("a" | "b")+"#)
  }

  @Test
  func `Reversed Concatenation Element Order`() {
    let grammar = Grammar(startingSymbol: "expression") {
      Production("expression") {
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
        Production("expression") {
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
      Production("expression") {
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
        Production("expression") {
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
      Production("expression") {
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
        Production("expression") {
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
      Production("expression") {
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
        Production("expression") {
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
      Production("expression") {
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
        Production("expression") {
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
      Production("expression") {
        Ref("term")
      }
      Production("term") {
        Ref("factor")
      }
      Production("factor") {
        "value"
      }
      Production("dead") {
        "unreachable"
      }
    }

    let reversed = grammar.reversed()

    expectNoDifference(
      reversed,
      Grammar(startingSymbol: "expression") {
        Production("expression") {
          Ref("term")
        }
        Production("term") {
          Ref("factor")
        }
        Production("factor") {
          "value"
        }
      }
    )
    expectNoDifference(reversed.containsProduction(for: "dead"), false)
  }

  @Test
  func `Mutating Reverse Updates Grammar`() {
    var grammar = Grammar(startingSymbol: "expression") {
      Production("expression") {
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
        Production("expression") {
          ConcatenateExpressions {
            "b"
            "a"
          }
        }
      }
    )
  }
}
