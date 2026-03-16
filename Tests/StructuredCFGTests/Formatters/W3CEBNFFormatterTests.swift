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
  func `Formatting Empty Production Throws`() {
    let grammar = Grammar(startingSymbol: "padding") {
      Rule("padding") {
        EmptyExpression()
      }
    }

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .w3cEbnf)
    }
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
  func `Formatting Optional Of Empty Throws`() {
    let grammar = Grammar(Rule("start") {
      OptionalExpression {
        EmptyExpression()
      }
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .w3cEbnf)
    }
  }

  @Test
  func `Formatting Zero Or More Of Empty Throws`() {
    let grammar = Grammar(Rule("start") {
      ZeroOrMore {
        EmptyExpression()
      }
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .w3cEbnf)
    }
  }

  @Test
  func `Formatting Group Of Empty Throws`() {
    let grammar = Grammar(Rule("start") {
      Group {
        EmptyExpression()
      }
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .w3cEbnf)
    }
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

  @Test
  func `Terminals Are Quoted With Single Quotes`() {
    var formatter = Grammar.W3CEBNFFormatter()
    formatter.quoting = .single

    let grammar = Grammar(Rule("start") {
      "hello"
    })

    expectNoDifference(
      try grammar.formatted(with: formatter),
      #"start ::= 'hello'"#
    )
  }

  @Test
  func `Single Quotes In Terminal Are Escaped With Single Quoting`() {
    var formatter = Grammar.W3CEBNFFormatter()
    formatter.quoting = .single

    let grammar = Grammar(Rule("start") {
      "it's"
    })

    expectNoDifference(
      try grammar.formatted(with: formatter),
      #"start ::= 'it\'s'"#
    )
  }

  @Test
  func `Backslash In Terminal Is Escaped With Single Quoting`() {
    var formatter = Grammar.W3CEBNFFormatter()
    formatter.quoting = .single

    let grammar = Grammar(Rule("start") {
      #"path\to\file"#
    })

    expectNoDifference(
      try grammar.formatted(with: formatter),
      #"start ::= 'path\\to\\file'"#
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
      try grammar.formatted(with: .w3cEbnf)
    }
  }
}
