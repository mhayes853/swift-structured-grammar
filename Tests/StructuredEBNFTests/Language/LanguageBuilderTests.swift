import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `LanguageBuilder tests` {
  @Test
  func `Empty Builder Produces Empty Language`() {
    let language = Language {
    }

    expectNoDifference(language.grammar(), Grammar())
  }

  @Test
  func `Builder Accepts Single Grammar`() {
    let language = Language {
      Grammar(Production("expression") { "value" })
    }

    expectNoDifference(
      language.grammar(),
      Grammar(Production("expression") { "value" })
    )
  }

  @Test
  func `Builder Supports Optional Language`() {
    let includeGrammar = false
    let language = Language {
      if includeGrammar {
        Grammar(Production("expression") { "value" })
      }
    }

    expectNoDifference(language.grammar(), Grammar())
  }

  @Test
  func `Builder Supports Conditional Branches`() {
    let usePrimary = true
    let language = Language {
      if usePrimary {
        Grammar(Production("expression") { "value" })
      } else {
        Grammar(Production("term") { "other" })
      }
    }

    expectNoDifference(
      language.grammar(),
      Grammar(Production("expression") { "value" })
    )
  }
}
