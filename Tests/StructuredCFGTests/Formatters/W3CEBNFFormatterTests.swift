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
          ChoiceOf {
            "+"
            "-"
          }
        }
      }

      Rule("term") {
        ChoiceOf {
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
              ChoiceOf {
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
      ChoiceOf {
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
        ChoiceOf {
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
  func `XML Character Class Escapes Round Trip In W3C Formatter`() throws {
    let grammar = Grammar(Rule("start") {
      CharacterGroup("\\i\\C")
    })

    expectNoDifference(
      try grammar.formatted(with: .w3cEbnf),
      #"start ::= [\i\C]"#
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
      #"start ::= 'it'#x27's'"#
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
  func `Comments Use ISO Style When Configured`() throws {
    let grammar = Grammar(startingSymbol: "start") {
      Comment("A comment")
      Rule("start") { "value" }
    }

    expectNoDifference(
      try grammar.formatted(with: .w3cEbnf(commentStyle: .iso)),
      "(* A comment *)\nstart ::= \"value\""
    )
  }

  @Test
  func `Comments Use Single Line Style When Configured`() throws {
    let grammar = Grammar(startingSymbol: "start") {
      Comment("A comment")
      Rule("start") { "value" }
    }

    expectNoDifference(
      try grammar.formatted(with: .w3cEbnf(commentStyle: .line)),
      "// A comment\nstart ::= \"value\""
    )
  }

  @Test
  func `Comments Are Omitted When Disabled`() throws {
    let grammar = Grammar(startingSymbol: "start") {
      Comment("A comment")
      Rule("start") { "value" }
    }

    expectNoDifference(
      try grammar.formatted(with: .w3cEbnf(commentStyle: .none)),
      "start ::= \"value\""
    )
  }

  @Test
  func `Mixed Hex Terminal Uses Single W3C Terminal`() throws {
    let grammar = Grammar(Rule("start") {
      Terminal(characters: [.hex("a".unicodeScalars.first!), .character("a")])
    })

    expectNoDifference(
      try grammar.formatted(with: .w3cEbnf),
      #"start ::= #x61"a""#
    )
  }

  @Test
  func `Unicode Terminal Decodes In W3C Formatter`() throws {
    let grammar = Grammar(Rule("start") {
      Terminal(unicode: Unicode.Scalar(UInt32(0x1F600))!)
    })

    expectNoDifference(try grammar.formatted(with: .w3cEbnf), #"start ::= "😀""#)
  }

  @Test
  func `Unicode Character Group Decodes In W3C Formatter`() throws {
    let grammar = Grammar(Rule("start") {
      CharacterGroup("\\U0001F600")
    })

    expectNoDifference(try grammar.formatted(with: .w3cEbnf), #"start ::= [#x1f600]"#)
  }

  @Test
  func `All Character Group Uses Full W3C Range`() throws {
    let grammar = Grammar(Rule("start") {
      CharacterGroup.all
    })

    expectNoDifference(
      try grammar.formatted(with: .w3cEbnf),
      #"start ::= [#x9#xA#xD#x20-#xD7FF#xE000-#xFFFD#x10000-#x10FFFF]"#
    )
  }

  @Test
  func `Negated All Character Group Uses Negated W3C Range`() throws {
    let grammar = Grammar(Rule("start") {
      CharacterGroup.all.negated()
    })

    expectNoDifference(
      try grammar.formatted(with: .w3cEbnf),
      #"start ::= [^#x9#xA#xD#x20-#xD7FF#xE000-#xFFFD#x10000-#x10FFFF]"#
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
