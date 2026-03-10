import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `Language tests` {
  @Test
  func `Empty Initialization Resolves To Empty Grammar`() {
    let language = Language()

    expectNoDifference(language.grammar, Grammar())
  }

  @Test
  func `Grammar Lifts To Language`() {
    let grammar = Grammar {
      Production("expression") { "value" }
    }

    expectNoDifference(
      grammar.language.grammar,
      Grammar {
        Production("g0__expression") { "value" }
      }
    )
  }

  @Test
  func `Format Delegates To Grammar Formatting`() {
    let language = Grammar {
      Production("expression") { "value" }
    }.language

    expectNoDifference(language.format(), "g0__expression = \"value\" ;")
  }
}
