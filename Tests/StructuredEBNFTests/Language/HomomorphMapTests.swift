import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `HomomorphMap tests` {
  @Test
  func `HomomorphMap Eagerly Rewrites Inner Language Grammar`() {
    let language = HomomorphMap {
      Grammar(startingIdentifier: "expression") {
        Production("expression") {
          Choice {
            "+"
            "*"
          }
        }
      }
    } transform: { terminal -> Terminal? in
      if terminal == "+" {
        return "-"
      } else {
        return nil
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(Production("expression") {
        Choice {
          "-"
          "*"
        }
      })
    )
  }
}
