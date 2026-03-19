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
        Epsilon()
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
        Epsilon()
        "a"
        Ref("target")
      }
    })

    expectNoDifference(try grammar.formatted(with: .w3cEbnf), #"start ::= "a" target"#)
  }

  @Test
  func `Formatting Choice With Semantic Epsilon Throws`() {
    let grammar = Grammar(Rule("start") {
      Choice {
        Epsilon()
        "a"
        "b"
      }
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .w3cEbnf)
    }
  }

  @Test
  func `Formatting Optional Of Empty Throws`() {
    let grammar = Grammar(Rule("start") {
      OptionalExpression {
        Epsilon()
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
        Epsilon()
      }
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .w3cEbnf)
    }
  }

  @Test
  func `Formatting Group Of Empty Throws`() {
    let grammar = Grammar(Rule("start") {
      GroupExpression {
        Epsilon()
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
  func `Canonical Character Groups Use Bracketed W3C Shorthand`() {
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
      Rule("nonDigit") {
        CharacterGroup("\\D")
      }
      Rule("nonWord") {
        CharacterGroup("\\W")
      }
      Rule("nonSpace") {
        CharacterGroup("\\S")
      }
      Rule("combo") {
        CharacterGroup("\\w\\d")
      }
      Rule("prefixed") {
        CharacterGroup("a\\d")
      }
    }

    expectNoDifference(
      try grammar.formatted(with: .w3cEbnf),
      #"""
      start ::= [\d]
      word ::= [\w]
      space ::= [\s]
      nonDigit ::= [\D]
      nonWord ::= [\W]
      nonSpace ::= [\S]
      combo ::= [\w\d]
      prefixed ::= [a\d]
      """#
    )
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
  func `Mixed Hex Terminal Uses Single W3C Terminal`() throws {
    let grammar = Grammar(Rule("start") {
      Terminal(parts: [.hex(["a".unicodeScalars.first!]), .string("a")])
    })

    expectNoDifference(
      try grammar.formatted(with: .w3cEbnf),
      #"start ::= #x61"a""#
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

  @Test
  func `Formatting Special Sequence Throws`() {
    let grammar = Grammar(Rule("space") {
      Special("ASCII character 32")
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .w3cEbnf)
    }
  }
}
