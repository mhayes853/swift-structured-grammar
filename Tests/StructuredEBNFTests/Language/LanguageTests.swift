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

  @Test
  func `Concatenated Returns New Language Without Mutating Original`() {
    let base = Language {
      Grammar(Production("expression") { "value" })
    }

    let concatenated = base.concatenated(Grammar(Production("statement") { "other" }))

    expectNoDifference(
      base.grammar(),
      Grammar(Production("expression") { "value" })
    )
    expectNoDifference(
      concatenated.grammar(),
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
  func `Mutating Concatenate Updates Language`() {
    var language = Language {
      Grammar(Production("expression") { "value" })
    }

    language.concatenate(Grammar(Production("statement") { "other" }))

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
  func `Unioned Returns New Language Without Mutating Original`() {
    let base = Language {
      Grammar(Production("expression") { "value" })
    }

    let unioned = base.unioned(Grammar(Production("statement") { "other" }))

    expectNoDifference(
      base.grammar(),
      Grammar(Production("expression") { "value" })
    )
    expectNoDifference(
      unioned.grammar(),
      Grammar(startingIdentifier: .root) {
        Production(.root) { Ref("l0__start") }
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

  @Test
  func `Mutating Union Updates Language`() {
    var language = Language {
      Grammar(Production("expression") { "value" })
    }

    language.formUnion(Grammar(Production("statement") { "other" }))

    expectNoDifference(
      language.grammar(),
      Grammar(startingIdentifier: .root) {
        Production(.root) { Ref("l0__start") }
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

  @Test
  func `KleeneStarred Returns New Language Without Mutating Original`() {
    let base = Language {
      Grammar(Production("expression") { "value" })
    }

    let starred = base.kleeneStarred()

    expectNoDifference(
      base.grammar(),
      Grammar(Production("expression") { "value" })
    )
    expectNoDifference(
      starred.grammar(),
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
  func `Mutating KleeneStar Updates Language`() {
    var language = Language {
      Grammar(Production("expression") { "value" })
    }

    language.formKleeneStar()

    expectNoDifference(
      language.grammar(),
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
  func `Reversed Returns New Language Without Mutating Original`() {
    let base = Language {
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

    let reversed = base.reversed()

    expectNoDifference(
      base.grammar(),
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
    expectNoDifference(
      reversed.grammar(),
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
  func `Mutating Reverse Updates Language`() {
    var language = Language {
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

    language.reverse()

    expectNoDifference(
      language.grammar(),
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
}
