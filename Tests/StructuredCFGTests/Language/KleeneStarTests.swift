import CustomDump
import Testing
import StructuredCFG

@Suite
struct `KleeneStar tests` {
  @Test
  func `KleeneStar Synthesizes Repetition Start Production`() {
    let language = KleeneStar {
      Grammar(Production("expression") { "value" })
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(startingSymbol: .root) {
        Production(.root) { Ref("lastart") }
        Production("expression") { "value" }
        Production("lastart") {
          ZeroOrMore {
            Ref("expression")
          }
        }
      }
    )
  }

  @Test
  func `Static KleeneStar Helper Matches Wrapper`() {
    let wrapper = KleeneStar {
      Grammar(Production("expression") { "value" })
    }.language
    let helper = Language.kleeneStar(Grammar(Production("expression") { "value" }))

    expectNoDifference(helper.grammar(), wrapper.grammar())
  }
}
