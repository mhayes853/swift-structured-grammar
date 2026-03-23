import CustomDump
import StructuredCFG
import Testing

@Suite
struct `Reverse tests` {
  @Test
  func `Reverse Rewrites Reachable Productions`() {
    let language = Reverse {
      Grammar(startingSymbol: "expression") {
        Rule("expression") {
          ConcatenateExpressions {
            "a"
            Ref("term")
          }
        }
        Rule("term") {
          ConcatenateExpressions {
            "b"
            "c"
          }
        }
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("expression") }
        Rule("expression") {
          ConcatenateExpressions {
            Ref("term")
            "a"
          }
        }
        Rule("term") {
          ConcatenateExpressions {
            "c"
            "b"
          }
        }
      }
    )
  }

  @Test
  func `Reverse Rewrites All Reachable Productions And Omits Unreachable Ones`() {
    let language = Reverse {
      Grammar(startingSymbol: "expression") {
        Rule("expression") {
          ConcatenateExpressions {
            "a"
            Ref("term")
          }
        }
        Rule("term") {
          ConcatenateExpressions {
            Ref("factor")
            "b"
          }
        }
        Rule("factor") {
          Choice {
            "c"
            GroupExpression {
              "d"
              "e"
            }
          }
        }
        Rule("dead") {
          "z"
        }
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("expression") }
        Rule("expression") {
          ConcatenateExpressions {
            Ref("term")
            "a"
          }
        }
        Rule("term") {
          ConcatenateExpressions {
            "b"
            Ref("factor")
          }
        }
        Rule("factor") {
          Choice {
            "c"
            GroupExpression {
              "e"
              "d"
            }
          }
        }
      }
    )
  }

  @Test
  func `Static Reverse Helper Matches Wrapper`() {
    let wrapper = Reverse {
      Grammar(startingSymbol: "expression") {
        Rule("expression") {
          ConcatenateExpressions {
            "a"
            Ref("term")
          }
        }
        Rule("term") {
          ConcatenateExpressions {
            "b"
            "c"
          }
        }
      }
    }.language
    let helper = Language.reverse(
      Grammar(startingSymbol: "expression") {
        Rule("expression") {
          ConcatenateExpressions {
            "a"
            Ref("term")
          }
        }
        Rule("term") {
          ConcatenateExpressions {
            "b"
            "c"
          }
        }
      }
    )

    expectNoDifference(helper.grammar(), wrapper.grammar())
  }

  @Test
  func `Reverse Formats Rewritten Language In W3C`() throws {
    let language = Reverse {
      Grammar(startingSymbol: "expression") {
        Rule("expression") {
          ConcatenateExpressions {
            "a"
            Ref("term")
          }
        }
        Rule("term") {
          ConcatenateExpressions {
            "b"
            "c"
          }
        }
      }
    }

    expectNoDifference(
      try language.language.formatted(with: .w3cEbnf),
      """
      root ::= expression
      expression ::= term "a"
      term ::= "c" "b"
      """
    )
  }

  @Test
  func `Reverse XGrammar Matches Reversed Sequence Only`() async throws {
    let language = Reverse {
      Grammar(startingSymbol: "expression") {
        Rule("expression") {
          ConcatenateExpressions {
            "a"
            Ref("term")
          }
        }
        Rule("term") {
          ConcatenateExpressions {
            "b"
            "c"
          }
        }
      }
    }
    .language

    let reversedMatch = try await XGrammarTestSupport.matches("cba", language: language)
    let originalMatch = try await XGrammarTestSupport.matches("abc", language: language)
    let partialMatch = try await XGrammarTestSupport.matches("cb", language: language)

    expectNoDifference(reversedMatch, true)
    expectNoDifference(originalMatch, false)
    expectNoDifference(partialMatch, false)
  }
}
