import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `Language tests` {
  @Test
  func `Empty Initialization Resolves To Empty Grammar`() {
    let language = Language()

    expectNoDifference(language.grammar(), Grammar())
  }

  @Test
  func `Grammar Lifts To Language`() {
    let grammar = Grammar(Production("expression") { "value" })

    expectNoDifference(grammar.language.grammar(), grammar)
  }

  @Test
  func `Format Delegates To Grammar Formatting`() {
    let language = Grammar(Production("expression") { "value" }).language

    expectNoDifference(language.format(), "expression = \"value\" ;")
  }

  @Test
  func `Grammar Uses Default Root Identifier When Language Synthesizes Start Production`() {
    let language = ConcatenateLanguages {
      Grammar(Production("expression") { "value" })
      Grammar(Production("statement") { "other" })
    }.language

    expectNoDifference(
      language.grammar(),
      Grammar(startingIdentifier: .root) {
        Production(.root) { Ref("l0__start") }
        Production("expression") { "value" }
        Production("statement") { "other" }
        Production("l0__start") {
          Ref("expression")
          Ref("statement")
        }
      }
    )
  }

  @Test
  func `Grammar Supports Custom Starting Identifier`() {
    let language = Union {
      Grammar(Production("expression") { "value" })
      Grammar(Production("statement") { "other" })
    }.language

    expectNoDifference(
      language.grammar(startingIdentifier: "entry"),
      Grammar(startingIdentifier: "entry") {
        Production("entry") { Ref("l0__start") }
        Production("expression") { "value" }
        Production("statement") { "other" }
        Production("l0__start") {
          Choice {
            Ref("expression")
            Ref("statement")
          }
        }
      }
    )
  }
}
