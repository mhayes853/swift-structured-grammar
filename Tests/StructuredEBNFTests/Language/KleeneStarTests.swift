import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `KleeneStar tests` {
  @Test
  func `KleeneStar Synthesizes Repetition Start Production`() {
    let language = KleeneStar {
      Grammar(Production("expression") { "value" })
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(startingIdentifier: .root) {
        Production(.root) { Ref("l0__start") }
        Production("expression") { "value" }
        Production("l0__start") {
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
