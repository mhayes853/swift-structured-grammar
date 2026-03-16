import CustomDump
import Testing
import StructuredCFG

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
            Group {
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
            Group {
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
}
