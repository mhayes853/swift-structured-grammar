import CustomDump
import Testing
import StructuredCFG

@Suite
struct `GBNFFormatter tests` {
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
      grammar.formatted(with: .gbnf),
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

    expectNoDifference(grammar.formatted(with: .gbnf), "")
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

    expectNoDifference(grammar.formatted(with: .gbnf), #"start ::= "a" target"#)
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

    expectNoDifference(grammar.formatted(with: .gbnf), #"start ::= "a" | "b""#)
  }

  @Test
  func `Formatting Optional Of Empty Disappears`() {
    let grammar = Grammar(Production("start") {
      OptionalExpression {
        EmptyExpression()
      }
    })

    expectNoDifference(grammar.formatted(with: .gbnf), "")
  }

  @Test
  func `Formatting Zero Or More Of Empty Disappears`() {
    let grammar = Grammar(Production("start") {
      ZeroOrMore {
        EmptyExpression()
      }
    })

    expectNoDifference(grammar.formatted(with: .gbnf), "")
  }

  @Test
  func `Formatting Group Of Empty Disappears`() {
    let grammar = Grammar(Production("start") {
      Group {
        EmptyExpression()
      }
    })

    expectNoDifference(grammar.formatted(with: .gbnf), "")
  }

  @Test
  func `Formatting One Or More Uses GBNF Syntax`() {
    let grammar = Grammar(Production("start") {
      OneOrMore {
        Choice {
          "a"
          "b"
        }
      }
    })

    expectNoDifference(grammar.formatted(with: .gbnf), #"start ::= ("a" | "b")+"#)
  }

  @Test
  func `Terminals Are Quoted With Double Quotes`() {
    let grammar = Grammar(Production("start") {
      "hello"
    })

    expectNoDifference(grammar.formatted(with: .gbnf), #"start ::= "hello""#)
  }

  @Test
  func `Double Quotes In Terminal Are Escaped`() {
    let grammar = Grammar(Production("start") {
      "say \"hello\""
    })

    expectNoDifference(grammar.formatted(with: .gbnf), #"start ::= "say \"hello\"""#)
  }

  @Test
  func `Backslash In Terminal Is Escaped`() {
    let grammar = Grammar(Production("start") {
      "path\\to\\file"
    })

    expectNoDifference(grammar.formatted(with: .gbnf), #"start ::= "path\\to\\file""#)
  }

  @Test
  func `Negated Character Groups Use GBNF Syntax`() {
    let grammar = Grammar(Production("start") {
      CharacterGroup("[^abc]")
    })

    expectNoDifference(grammar.formatted(with: .gbnf), #"start ::= [^abc]"#)
  }

  @Test
  func `Character Group Ranges Use GBNF Syntax`() {
    let grammar = Grammar(Production("start") {
      CharacterGroup("[a-z]")
    })

    expectNoDifference(grammar.formatted(with: .gbnf), #"start ::= [a-z]"#)
  }

  @Test
  func `Predefined Character Classes Use GBNF Syntax`() {
    let grammar = Grammar(startingSymbol: "start") {
      Production("start") {
        CharacterGroup("[\\d]")
      }
      Production("word") {
        CharacterGroup("[\\w]")
      }
      Production("space") {
        CharacterGroup("[\\s]")
      }
      Production("digit") {
        CharacterGroup("[\\D]")
      }
      Production("nonWord") {
        CharacterGroup("[\\W]")
      }
      Production("nonSpace") {
        CharacterGroup("[\\S]")
      }
      Production("any") {
        CharacterGroup("[.]")
      }
    }

    expectNoDifference(
      grammar.formatted(with: .gbnf),
      """
      start ::= [\\d]
      word ::= [\\w]
      space ::= [\\s]
      digit ::= [\\D]
      nonWord ::= [\\W]
      nonSpace ::= [\\S]
      any ::= [.]
      """
    )
  }
}
