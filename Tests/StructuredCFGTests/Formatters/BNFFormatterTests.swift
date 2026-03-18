import CustomDump
import Testing
import StructuredCFG

@Suite
struct `BNFFormatter tests` {
  @Test
  func `Formats Simple Rules With Traditional BNF Syntax`() throws {
    let grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") {
        Choice {
          Ref("term")
          "identifier"
        }
      }

      Rule("term") {
        "number"
      }
    }

    expectNoDifference(
      try grammar.formatted(with: .bnf),
      #"""
      <expression> ::= <term> | "identifier"
      <term> ::= "number"
      """#
    )
  }

  @Test
  func `Formats Optional Using Brackets`() throws {
    let grammar = Grammar(Rule("sign") {
      OptionalExpression {
        Choice {
          "+"
          "-"
        }
      }
    })

    expectNoDifference(
      try grammar.formatted(with: .bnf),
      #"<sign> ::= ["+" | "-"]"#
    )
  }

  @Test
  func `Formats Non Trivial Grammar Exactly`() throws {
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
      try grammar.formatted(with: .bnf),
      #"""
      <sign> ::= ["+" | "-"]
      <term> ::= <number> | "(" <expression> ")" | "identifier"
      <expression> ::= <sign> <term> <expression__bnf_1>
      <expression__bnf_1> ::= "" | "+" <term> <expression__bnf_1> | "-" <term> <expression__bnf_1>
      """#
    )
  }

  @Test
  func `Character Groups Expand Into Alternation`() throws {
    let grammar = Grammar(Rule("start") {
      CharacterGroup("a-c")
    })

    expectNoDifference(
      try grammar.formatted(with: .bnf),
      #"<start> ::= "a" | "b" | "c""#
    )
  }

  @Test
  func `One Or More Lowers Into Right Recursive Helper`() throws {
    let grammar = Grammar(Rule("digits") {
      OneOrMore {
        "a"
      }
    })

    expectNoDifference(
      try grammar.formatted(with: .bnf),
      #"""
      <digits> ::= "a" <digits__bnf_1>
      <digits__bnf_1> ::= "" | "a" <digits__bnf_1>
      """#
    )
  }

  @Test
  func `At Most Repeat Uses Optional Wrapped Union`() throws {
    let grammar = Grammar(Rule("upto5") {
      Repeat(...3) {
        "a"
      }
    })

    expectNoDifference(
      try grammar.formatted(with: .bnf),
      #"<upto5> ::= ["a" | "a" "a" | "a" "a" "a"]"#
    )
  }

  @Test
  func `Formatting Empty Productions Outputs Empty Terminal String`() throws {
    let grammar = Grammar(Rule("padding") {
      EmptyExpression()
    })

    expectNoDifference(try grammar.formatted(with: .bnf), #"<padding> ::= """#)
  }

  @Test
  func `Formatting Special Sequence Throws`() {
    let grammar = Grammar(Rule("space") {
      Special("ASCII character 32")
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .bnf)
    }
  }

  @Test
  func `Formatting Custom Expression Throws`() {
    struct CustomExpr: Hashable, Sendable {
      let value: String
    }

    let grammar = Grammar(Rule("start") {
      Expression.custom(CustomExpr(value: "test"))
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .bnf)
    }
  }
}
