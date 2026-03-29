import CustomDump
import StructuredCFG
import Testing

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
  func `Lowers Optional Into An Explicit Empty Alternative`() throws {
    let grammar = Grammar(
      Rule("sign") {
        OptionalExpression {
          Choice {
            "+"
            "-"
          }
        }
      }
    )

    expectNoDifference(
      try grammar.formatted(with: .bnf),
      #"<sign> ::= "" | "+" | "-""#
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
          GroupExpression {
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
            GroupExpression {
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
      <sign> ::= "" | "+" | "-"
      <term> ::= <number> | "(" <expression> ")" | "identifier"
      <expression> ::= <sign> <term> <expression__bnf_1>
      <expression__bnf_1> ::= "" | "+" <term> <expression__bnf_1> | "-" <term> <expression__bnf_1>
      """#
    )
  }

  @Test
  func `Character Groups Expand Into Alternation`() throws {
    let grammar = Grammar(
      Rule("start") {
        CharacterGroup("a-c")
      }
    )

    expectNoDifference(
      try grammar.formatted(with: .bnf),
      #"<start> ::= "a" | "b" | "c""#
    )
  }

  @Test
  func `One Or More Lowers Into Right Recursive Helper`() throws {
    let grammar = Grammar(
      Rule("digits") {
        OneOrMore {
          "a"
        }
      }
    )

    expectNoDifference(
      try grammar.formatted(with: .bnf),
      #"""
      <digits> ::= "a" <digits__bnf_1>
      <digits__bnf_1> ::= "" | "a" <digits__bnf_1>
      """#
    )
  }

  @Test
  func `At Most Repeat Lowers Into An Explicit Empty Alternative`() throws {
    let grammar = Grammar(
      Rule("upto5") {
        Repeat(...3) {
          "a"
        }
      }
    )

    expectNoDifference(
      try grammar.formatted(with: .bnf),
      #"<upto5> ::= "" | "a" | "a" "a" | "a" "a" "a""#
    )
  }

  @Test
  func `Formatting All Character Group Throws`() {
    let grammar = Grammar(
      Rule("start") {
        CharacterGroup.all
      }
    )

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .bnf)
    }
  }

  @Test
  func `Formatting Control Characters Renders Without Throwing`() throws {
    let grammar = Grammar(
      Rule("whitespace") {
        Choice {
          "\n"
          "\r"
          "\t"
        }
      }
    )

    let formatted = try grammar.formatted(with: .bnf)
    expectNoDifference(formatted, #"<whitespace> ::= "\n" | "\r" | "\t""#)
  }

  @Test
  func `Formatting Backslash Renders Without Throwing`() throws {
    let grammar = Grammar(
      Rule("start") {
        #"\"#
      }
    )

    let formatted = try grammar.formatted(with: .bnf)
    expectNoDifference(formatted, #"<start> ::= "\\""#)
  }

  @Test
  func `Formatting Empty Productions Outputs Empty Terminal String`() throws {
    let grammar = Grammar(
      Rule("padding") {
        Epsilon()
      }
    )

    expectNoDifference(try grammar.formatted(with: .bnf), #"<padding> ::= """#)
  }

  @Test
  func `Comments Use ISO Style When Configured`() throws {
    let grammar = Grammar(startingSymbol: "start") {
      Comment("A comment")
      Rule("start") { "value" }
    }

    expectNoDifference(
      try grammar.formatted(with: .bnf(commentStyle: .iso)),
      "(* A comment *)\n<start> ::= \"value\""
    )
  }

  @Test
  func `Comments Use Single Line Style When Configured`() throws {
    let grammar = Grammar(startingSymbol: "start") {
      Comment("A comment")
      Rule("start") { "value" }
    }

    expectNoDifference(
      try grammar.formatted(with: .bnf(commentStyle: .line)),
      "// A comment\n<start> ::= \"value\""
    )
  }

  @Test
  func `Comments Are Omitted When Disabled`() throws {
    let grammar = Grammar(startingSymbol: "start") {
      Comment("A comment")
      Rule("start") { "value" }
    }

    expectNoDifference(
      try grammar.formatted(with: .bnf(commentStyle: .none)),
      "<start> ::= \"value\""
    )
  }

  @Test
  func `Formatting Special Sequence Throws`() {
    let grammar = Grammar(
      Rule("space") {
        Special("ASCII character 32")
      }
    )

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .bnf)
    }
  }

  @Test
  func `Formatting Custom Expression Throws`() {
    struct CustomExpr: Hashable, Sendable {
      let value: String
    }

    let grammar = Grammar(
      Rule("start") {
        Expression.custom(CustomExpr(value: "test"))
      }
    )

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .bnf)
    }
  }
}
