import CustomDump
import Testing
import StructuredCFG

@Suite
struct `W3CEBNFFormatter tests` {
  @Test
  func `Formats Non Trivial Grammar Exactly`() {
    let grammar = Grammar(startingSymbol: "sign") {
      Rule("sign") {
        OptionalExpression {
          Choice {
            "+"
            "-"
          }
        }
      }

      Rule("term") {
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

      Rule("expression") {
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
      try grammar.formatted(with: .w3cEbnf),
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
      Rule("padding") {
        EmptyExpression()
      }
    }

    expectNoDifference(try grammar.formatted(with: .w3cEbnf), "")
  }

  @Test
  func `Formatting Concatenation Drops Empty Members`() {
    let grammar = Grammar(Rule("start") {
      ConcatenateExpressions {
        EmptyExpression()
        "a"
        Ref("target")
      }
    })

    expectNoDifference(try grammar.formatted(with: .w3cEbnf), #"start ::= "a" target"#)
  }

  @Test
  func `Formatting Choice Drops Empty Alternatives`() {
    let grammar = Grammar(Rule("start") {
      Choice {
        EmptyExpression()
        "a"
        "b"
      }
    })

    expectNoDifference(try grammar.formatted(with: .w3cEbnf), #"start ::= "a" | "b""#)
  }

  @Test
  func `Formatting Optional Of Empty Disappears`() {
    let grammar = Grammar(Rule("start") {
      OptionalExpression {
        EmptyExpression()
      }
    })

    expectNoDifference(try grammar.formatted(with: .w3cEbnf), "")
  }

  @Test
  func `Formatting Zero Or More Of Empty Disappears`() {
    let grammar = Grammar(Rule("start") {
      ZeroOrMore {
        EmptyExpression()
      }
    })

    expectNoDifference(try grammar.formatted(with: .w3cEbnf), "")
  }

  @Test
  func `Formatting Group Of Empty Disappears`() {
    let grammar = Grammar(Rule("start") {
      Group {
        EmptyExpression()
      }
    })

    expectNoDifference(try grammar.formatted(with: .w3cEbnf), "")
  }

  @Test
  func `Formatting One Or More Uses Native W3C Syntax`() {
    let grammar = Grammar(Rule("start") {
      OneOrMore {
        Choice {
          "a"
          "b"
        }
      }
    })

    expectNoDifference(try grammar.formatted(with: .w3cEbnf), #"start ::= ("a" | "b")+"#)
  }
}
