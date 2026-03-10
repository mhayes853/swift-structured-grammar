import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `Reverse tests` {
  @Test
  func `Reverse Rewrites Reachable Productions`() {
    let language = Reverse {
      Grammar(startingIdentifier: "expression") {
        Production("expression") {
          ConcatanateExpressions {
            "a"
            Ref("term")
          }
        }
        Production("term") {
          ConcatanateExpressions {
            "b"
            "c"
          }
        }
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(startingIdentifier: .root) {
        Production(.root) { Ref("expression") }
        Production("expression") {
          ConcatanateExpressions {
            Ref("term")
            "a"
          }
        }
        Production("term") {
          ConcatanateExpressions {
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
      Grammar(startingIdentifier: "expression") {
        Production("expression") {
          ConcatanateExpressions {
            "a"
            Ref("term")
          }
        }
        Production("term") {
          ConcatanateExpressions {
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
      Grammar(startingIdentifier: .root) {
        Production(.root) { Ref("expression") }
        Production("expression") {
          ConcatanateExpressions {
            Ref("term")
            "a"
          }
        }
        Production("term") {
          ConcatanateExpressions {
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
      Grammar(startingIdentifier: "expression") {
        Production("expression") {
          ConcatanateExpressions {
            "a"
            Ref("term")
          }
        }
        Production("term") {
          ConcatanateExpressions {
            "b"
            "c"
          }
        }
      }
    }.language
    let helper = Language.reverse(
      Grammar(startingIdentifier: "expression") {
        Production("expression") {
          ConcatanateExpressions {
            "a"
            Ref("term")
          }
        }
        Production("term") {
          ConcatanateExpressions {
            "b"
            "c"
          }
        }
      }
    )

    expectNoDifference(helper.grammar(), wrapper.grammar())
  }
}
