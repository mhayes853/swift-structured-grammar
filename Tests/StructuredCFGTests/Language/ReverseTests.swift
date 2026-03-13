import CustomDump
import Testing
import StructuredCFG

@Suite
struct `Reverse tests` {
  @Test
  func `Reverse Rewrites Reachable Productions`() {
    let language = Reverse {
      Grammar(startingSymbol: "expression") {
        Production("expression") {
          ConcatenateExpressions {
            "a"
            Ref("term")
          }
        }
        Production("term") {
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
        Production(.root) { Ref("expression") }
        Production("expression") {
          ConcatenateExpressions {
            Ref("term")
            "a"
          }
        }
        Production("term") {
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
        Production("expression") {
          ConcatenateExpressions {
            "a"
            Ref("term")
          }
        }
        Production("term") {
          ConcatenateExpressions {
            Ref("factor")
            "b"
          }
        }
        Production("factor") {
          Choice {
            "c"
            Group {
              "d"
              "e"
            }
          }
        }
        Production("dead") {
          "z"
        }
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(startingSymbol: .root) {
        Production(.root) { Ref("expression") }
        Production("expression") {
          ConcatenateExpressions {
            Ref("term")
            "a"
          }
        }
        Production("term") {
          ConcatenateExpressions {
            "b"
            Ref("factor")
          }
        }
        Production("factor") {
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
        Production("expression") {
          ConcatenateExpressions {
            "a"
            Ref("term")
          }
        }
        Production("term") {
          ConcatenateExpressions {
            "b"
            "c"
          }
        }
      }
    }.language
    let helper = Language.reverse(
      Grammar(startingSymbol: "expression") {
        Production("expression") {
          ConcatenateExpressions {
            "a"
            Ref("term")
          }
        }
        Production("term") {
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
