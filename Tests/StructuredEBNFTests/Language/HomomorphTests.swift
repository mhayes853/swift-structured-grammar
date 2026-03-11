import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `Homomorph tests` {
  @Test
  func `Homomorph Eagerly Rewrites Inner Language Grammar`() {
    let language = Homomorph("+", to: "-") {
      Grammar(startingSymbol: "expression") {
        Production("expression") {
          "+"
          Ref("term")
        }
        Production("term") {
          "+"
        }
      }
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(startingSymbol: "expression") {
        Production("expression") {
          "-"
          Ref("term")
        }
        Production("term") {
          "-"
        }
      }
    )
  }
}
