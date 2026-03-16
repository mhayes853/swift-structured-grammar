import CustomDump
import Testing
import StructuredCFG

@Suite
struct `KleeneStar tests` {
  @Test
  func `KleeneStar Synthesizes Repetition Start Production`() {
    let language = KleeneStar {
      Grammar(Rule("expression") { "value" })
    }

    expectNoDifference(
      language.language.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("lastart") }
        Rule("expression") { "value" }
        Rule("lastart") {
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
      Grammar(Rule("expression") { "value" })
    }.language
    let helper = Language.kleeneStar(Grammar(Rule("expression") { "value" }))

    expectNoDifference(helper.grammar(), wrapper.grammar())
  }
}
