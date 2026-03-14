import CustomDump
import Testing
import StructuredCFG

@Suite
struct `WirthEBNFFormatter tests` {
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
      Production("padding") {
        EmptyExpression()
      }
    }

    expectNoDifference(try grammar.formatted(with: .wirthEbnf), "")
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

    expectNoDifference(try grammar.formatted(with: .wirthEbnf), #"start = 'a' target ."#)
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

    expectNoDifference(try grammar.formatted(with: .wirthEbnf), #"start = 'a' | 'b' ."#)
  }

  @Test
  func `Formatting Optional Of Empty Disappears`() {
    let grammar = Grammar(Production("start") {
      OptionalExpression {
        EmptyExpression()
      }
    })

    expectNoDifference(try grammar.formatted(with: .wirthEbnf), "")
  }

  @Test
  func `Formatting Zero Or More Of Empty Disappears`() {
    let grammar = Grammar(Production("start") {
      ZeroOrMore {
        EmptyExpression()
      }
    })

    expectNoDifference(try grammar.formatted(with: .wirthEbnf), "")
  }

  @Test
  func `Formatting Group Of Empty Disappears`() {
    let grammar = Grammar(Production("start") {
      Group {
        EmptyExpression()
      }
    })

    expectNoDifference(try grammar.formatted(with: .wirthEbnf), "")
  }

  @Test
  func `Formatting One Or More Uses Wirth Syntax`() {
    let grammar = Grammar(Production("start") {
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
    let grammar = Grammar(Production("start") {
      CharacterGroup("^abc")
    })

    #expect(throws: Grammar.WirthEBNFFormatterError.self) {
      try grammar.formatted(with: .wirthEbnf)
    }
  }

  @Test
  func `Unicode Category Throws`() {
    let group = CharacterGroup(isNegated: false, members: [.category("Lu")])

    let grammar = Grammar(Production("start") {
      group
    })

    #expect(throws: Grammar.WirthEBNFFormatterError.self) {
      try grammar.formatted(with: .wirthEbnf)
    }
  }

  @Test
  func `Negated Unicode Category Throws`() {
    let group = CharacterGroup(isNegated: false, members: [.negatedCategory("Lu")])

    let grammar = Grammar(Production("start") {
      group
    })

    #expect(throws: Grammar.WirthEBNFFormatterError.self) {
      try grammar.formatted(with: .wirthEbnf)
    }
  }

  @Test
  func `XML Name Classes Throws`() {
    let group = CharacterGroup(isNegated: false, members: [.xmlName(.nameStart)])

    let grammar = Grammar(Production("start") {
      group
    })

    #expect(throws: Grammar.WirthEBNFFormatterError.self) {
      try grammar.formatted(with: .wirthEbnf)
    }
  }

  @Test
  func `Character Group Subtraction Throws`() {
    let innerGroup = CharacterGroup(isNegated: false, members: [.range("a", "z")])
    let group = CharacterGroup(isNegated: false, members: [.subtraction(innerGroup)])

    let grammar = Grammar(Production("start") {
      group
    })

    #expect(throws: Grammar.WirthEBNFFormatterError.self) {
      try grammar.formatted(with: .wirthEbnf)
    }
  }

  @Test
  func `Negated Predefined Class Throws`() {
    let group = CharacterGroup(isNegated: false, members: [.predefined(.nonDigit)])

    let grammar = Grammar(Production("start") {
      group
    })

    #expect(throws: Grammar.WirthEBNFFormatterError.self) {
      try grammar.formatted(with: .wirthEbnf)
    }
  }

  @Test
  func `Wildcard Throws`() {
    let group = CharacterGroup(isNegated: false, members: [.predefined(.wildcard)])

    let grammar = Grammar(Production("start") {
      group
    })

    #expect(throws: Grammar.WirthEBNFFormatterError.self) {
      try grammar.formatted(with: .wirthEbnf)
    }
  }
}
