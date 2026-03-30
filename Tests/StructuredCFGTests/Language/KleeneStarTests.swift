import CustomDump
import StructuredCFG
import Testing

@Suite
struct `Star tests` {
  @Test
  func `Star Synthesizes Repetition Start Production`() {
    let language = Star {
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
  func `Static Star Helper Matches Wrapper`() {
    let wrapper = Star {
      Grammar(Rule("expression") { "value" })
    }.language
    let helper = Language.star(Grammar(Rule("expression") { "value" }))

    expectNoDifference(helper.grammar(), wrapper.grammar())
  }

  @Test
  func `Star Formats As W3C Zero Or More`() throws {
    let language = Star {
      Grammar(startingSymbol: "token") {
        Rule("token") {
          ChoiceOf {
            "a"
            "b"
          }
        }
      }
    }

    expectNoDifference(
      try language.language.formatted(with: .w3cEbnf),
      """
      root ::= lastart
      token ::= "a" | "b"
      lastart ::= token*
      """
    )
  }

  @Test
  func `Star XGrammar Matches Empty And Repeated Inputs`() async throws {
    let language = Star {
      Grammar(startingSymbol: "token") {
        Rule("token") {
          ChoiceOf {
            "a"
            "b"
          }
        }
      }
    }
    .language

    let emptyMatch = try await XGrammarTestSupport.matches("", language: language)
    let repeatedMatch = try await XGrammarTestSupport.matches("abba", language: language)
    let invalidMatch = try await XGrammarTestSupport.matches("abc", language: language)

    expectNoDifference(emptyMatch, true)
    expectNoDifference(repeatedMatch, true)
    expectNoDifference(invalidMatch, false)
  }
}
