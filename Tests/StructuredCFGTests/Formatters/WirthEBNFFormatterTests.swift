import CustomDump
import Testing
import StructuredCFG

@Suite
struct `WirthEBNFFormatter tests` {
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
      try grammar.formatted(with: .wirthEbnf),
      """
      sign = ['+' | '-'] .
      term = number | ('(' expression ')') | 'identifier' .
      expression = sign term {('+' | '-') term} .
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

    expectNoDifference(try grammar.formatted(with: .wirthEbnf), "")
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

    expectNoDifference(try grammar.formatted(with: .wirthEbnf), #"start = 'a' target ."#)
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

    expectNoDifference(try grammar.formatted(with: .wirthEbnf), #"start = 'a' | 'b' ."#)
  }

  @Test
  func `Formatting Optional Of Empty Disappears`() {
    let grammar = Grammar(Rule("start") {
      OptionalExpression {
        EmptyExpression()
      }
    })

    expectNoDifference(try grammar.formatted(with: .wirthEbnf), "")
  }

  @Test
  func `Formatting Zero Or More Of Empty Disappears`() {
    let grammar = Grammar(Rule("start") {
      ZeroOrMore {
        EmptyExpression()
      }
    })

    expectNoDifference(try grammar.formatted(with: .wirthEbnf), "")
  }

  @Test
  func `Formatting Group Of Empty Disappears`() {
    let grammar = Grammar(Rule("start") {
      Group {
        EmptyExpression()
      }
    })

    expectNoDifference(try grammar.formatted(with: .wirthEbnf), "")
  }

  @Test
  func `Formatting One Or More Uses Wirth Syntax`() {
    let grammar = Grammar(Rule("start") {
      OneOrMore {
        Choice {
          "a"
          "b"
        }
      }
    })

    expectNoDifference(try grammar.formatted(with: .wirthEbnf), #"start = ('a' | 'b') {'a' | 'b'} ."#)
  }

  @Test
  func `Negated Character Group Throws`() {
    let grammar = Grammar(Rule("start") {
      CharacterGroup("^abc")
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .wirthEbnf)
    }
  }

  @Test
  func `Digit Character Group Expands To Alternation`() {
    let group = CharacterGroup("\\d")

    let grammar = Grammar(Rule("start") {
      group
    })

    expectNoDifference(
      try grammar.formatted(with: .wirthEbnf),
      #"start = '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' ."#
    )
  }

  @Test
  func `Whitespace Character Group Expands To Alternation`() {
    let group = CharacterGroup("\\s")

    let grammar = Grammar(Rule("start") {
      group
    })

    expectNoDifference(
      try grammar.formatted(with: .wirthEbnf),
      "start = ' ' | '\t' | '\n' | '\r' ."
    )
  }

  @Test
  func `Mixed Hex Terminal Decodes In Wirth`() throws {
    let grammar = Grammar(Rule("start") {
      Terminal(parts: [.hex(["a".unicodeScalars.first!]), .string("a")])
    })

    expectNoDifference(try grammar.formatted(with: .wirthEbnf), #"start = 'aa' ."#)
  }

  @Test
  func `Negated Predefined Class Throws`() {
    let group = CharacterGroup("\\D")

    let grammar = Grammar(Rule("start") {
      group
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .wirthEbnf)
    }
  }

  @Test
  func `NonASCII Range Throws`() {
    let group = CharacterGroup(isNegated: false, members: [.range("é", "ê")])

    let grammar = Grammar(Rule("start") {
      group
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .wirthEbnf)
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
      try grammar.formatted(with: .wirthEbnf)
    }
  }
}
