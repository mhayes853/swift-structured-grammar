import CustomDump
import Testing
import StructuredCFG

@Suite
struct `GBNFFormatter tests` {
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
      try grammar.formatted(with: .gbnf),
      """
      sign ::= ("+" | "-")?
      term ::= number | ("(" expression ")") | "identifier"
      expression ::= sign term (("+" | "-") term)*
      """
    )
  }

  @Test
  func `Formatting Empty Productions Outputs Empty Terminal String`() {
    let grammar = Grammar(startingSymbol: "padding") {
      Rule("padding") {
        Epsilon()
      }
    }

    expectNoDifference(try grammar.formatted(with: .gbnf), #"padding ::= """#)
  }

  @Test
  func `Formatting Concatenation Drops Empty Members`() {
    let grammar = Grammar(Rule("start") {
      ConcatenateExpressions {
        Epsilon()
        "a"
        Ref("target")
      }
    })

    expectNoDifference(try grammar.formatted(with: .gbnf), #"start ::= "a" target"#)
  }

  @Test
  func `Formatting Choice Preserves Semantic Epsilon Alternatives`() {
    let grammar = Grammar(Rule("start") {
      Choice {
        Epsilon()
        "a"
        "b"
      }
    })

    expectNoDifference(try grammar.formatted(with: .gbnf), #"start ::= "" | "a" | "b""#)
  }

  @Test
  func `Formatting Optional Of Empty Outputs Empty Terminal String`() {
    let grammar = Grammar(Rule("start") {
      OptionalExpression {
        Epsilon()
      }
    })

    expectNoDifference(try grammar.formatted(with: .gbnf), #"start ::= """#)
  }

  @Test
  func `Formatting Zero Or More Of Empty Outputs Empty Terminal String`() {
    let grammar = Grammar(Rule("start") {
      ZeroOrMore {
        Epsilon()
      }
    })

    expectNoDifference(try grammar.formatted(with: .gbnf), #"start ::= """#)
  }

  @Test
  func `Formatting Group Of Empty Outputs Empty Terminal String`() {
    let grammar = Grammar(Rule("start") {
      Group {
        Epsilon()
      }
    })

    expectNoDifference(try grammar.formatted(with: .gbnf), #"start ::= """#)
  }

  @Test
  func `Formatting One Or More Uses GBNF Syntax`() {
    let grammar = Grammar(Rule("start") {
      OneOrMore {
        Choice {
          "a"
          "b"
        }
      }
    })

    expectNoDifference(try grammar.formatted(with: .gbnf), #"start ::= ("a" | "b")+"#)
  }

  @Test
  func `Terminals Are Quoted With Double Quotes`() {
    let grammar = Grammar(Rule("start") {
      "hello"
    })

    expectNoDifference(try grammar.formatted(with: .gbnf), #"start ::= "hello""#)
  }

  @Test
  func `Double Quotes In Terminal Are Escaped`() {
    let grammar = Grammar(Rule("start") {
      "say \"hello\""
    })

    expectNoDifference(try grammar.formatted(with: .gbnf), #"start ::= "say \"hello\"""#)
  }

  @Test
  func `Mixed Hex Terminal Uses Single GBNF Terminal`() throws {
    let grammar = Grammar(Rule("start") {
      Terminal(parts: [.hex(["a".unicodeScalars.first!]), .string("a")])
    })

    expectNoDifference(
      try grammar.formatted(with: .gbnf),
      #"start ::= "\x61a""#
    )
  }

  @Test
  func `Backslash In Terminal Is Escaped`() {
    let grammar = Grammar(Rule("start") {
      "path\\to\\file"
    })

    expectNoDifference(try grammar.formatted(with: .gbnf), #"start ::= "path\\to\\file""#)
  }

  @Test
  func `Negated Character Groups Use GBNF Syntax`() {
    let grammar = Grammar(Rule("start") {
      CharacterGroup("^abc")
    })

    expectNoDifference(try grammar.formatted(with: .gbnf), #"start ::= [^abc]"#)
  }

  @Test
  func `Character Group Ranges Use GBNF Syntax`() {
    let grammar = Grammar(Rule("start") {
      CharacterGroup("a-z")
    })

    expectNoDifference(try grammar.formatted(with: .gbnf), #"start ::= [a-z]"#)
  }

  @Test
  func `Predefined Character Classes Use GBNF Syntax`() {
    let grammar = Grammar(startingSymbol: "start") {
      Rule("start") {
        CharacterGroup("\\d")
      }
      Rule("word") {
        CharacterGroup("\\w")
      }
      Rule("space") {
        CharacterGroup("\\s")
      }
      Rule("digit") {
        CharacterGroup("\\D")
      }
      Rule("nonWord") {
        CharacterGroup("\\W")
      }
      Rule("nonSpace") {
        CharacterGroup("\\S")
      }
      Rule("any") {
        CharacterGroup(".")
      }
    }

    expectNoDifference(
      try grammar.formatted(with: .gbnf),
      """
      start ::= [0-9]
      word ::= [a-zA-Z0-9_]
      space ::= [ \\t\\n\\r]
      digit ::= [^0-9]
      nonWord ::= [^a-zA-Z0-9_]
      nonSpace ::= [^ \\t\\n\\r]
      any ::= [.]
      """
    )
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
      try grammar.formatted(with: .gbnf)
    }
  }

  @Test
  func `Formatting Special Sequence Throws`() {
    let grammar = Grammar(Rule("space") {
      Special("ASCII character 32")
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .gbnf)
    }
  }
}
