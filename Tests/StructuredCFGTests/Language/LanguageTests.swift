import CustomDump
import StructuredCFG
import Testing

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

    expectNoDifference(language.formatted(with: .w3cEbnf), #"expression ::= "value""#)
  }

  @Test
  func `Grammar Uses Default Root Identifier When Language Synthesizes Start Production`() {
    let language = ConcatenateLanguages {
      Grammar(Production("expression") { "value" })
      Grammar(Production("statement") { "other" })
    }
    .language

    expectNoDifference(
      language.grammar(),
      Grammar(startingSymbol: .root) {
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
    }
    .language

    expectNoDifference(
      language.grammar(startingSymbol: "entry"),
      Grammar(startingSymbol: "entry") {
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
      Grammar(startingSymbol: .root) {
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
      Grammar(startingSymbol: .root) {
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
      Grammar(startingSymbol: .root) {
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
      Grammar(startingSymbol: .root) {
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
      Grammar(startingSymbol: .root) {
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
      Grammar(startingSymbol: .root) {
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
      Grammar(startingSymbol: "expression") {
        Production("expression") {
          ConcatenateExpressions {
            "a"
            Ref("term")
          }
        }
        Production("term") {
          ConcatenateExpressions {
            "b"
            "c"
          }
        }
      }
    }

    let reversed = base.reversed()

    expectNoDifference(
      base.grammar(),
      Grammar(startingSymbol: "expression") {
        Production("expression") {
          ConcatenateExpressions {
            "a"
            Ref("term")
          }
        }
        Production("term") {
          ConcatenateExpressions {
            "b"
            "c"
          }
        }
      }
    )
    expectNoDifference(
      reversed.grammar(),
      Grammar(startingSymbol: .root) {
        Production(.root) { Ref("expression") }
        Production("expression") {
          ConcatenateExpressions {
            Ref("term")
            "a"
          }
        }
        Production("term") {
          ConcatenateExpressions {
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
      Grammar(startingSymbol: "expression") {
        Production("expression") {
          ConcatenateExpressions {
            "a"
            Ref("term")
          }
        }
        Production("term") {
          ConcatenateExpressions {
            "b"
            "c"
          }
        }
      }
    }

    language.reverse()

    expectNoDifference(
      language.grammar(),
      Grammar(startingSymbol: .root) {
        Production(.root) { Ref("expression") }
        Production("expression") {
          ConcatenateExpressions {
            Ref("term")
            "a"
          }
        }
        Production("term") {
          ConcatenateExpressions {
            "c"
            "b"
          }
        }
      }
    )
  }

  @Test
  func `Homomorphed Returns New Language Without Mutating Original`() {
    let base = Language {
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

    let homomorphed = base.homomorphed("+", to: "-")

    expectNoDifference(
      base.grammar(),
      Grammar(startingSymbol: "expression") {
        Production("expression") {
          "+"
          Ref("term")
        }
        Production("term") {
          "+"
        }
      }
    )
    expectNoDifference(
      homomorphed.grammar(),
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

  @Test
  func `Mutating Homomorph Updates Language`() {
    var language = Language {
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

    language.homomorph("+", to: "-")

    expectNoDifference(
      language.grammar(),
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

  @Test
  func `HomomorphMapped Returns New Language Without Mutating Original`() {
    let base = Language {
      Grammar(
        Production("expression") {
          Choice {
            "+"
            "*"
          }
        }
      )
    }

    let homomorphed = base.homomorphMapped { terminal -> Terminal? in
      if terminal == "+" {
        return "-"
      } else {
        return nil
      }
    }

    expectNoDifference(
      base.grammar(),
      Grammar(
        Production("expression") {
          Choice {
            "+"
            "*"
          }
        }
      )
    )
    expectNoDifference(
      homomorphed.grammar(),
      Grammar(
        Production("expression") {
          Choice {
            "-"
            "*"
          }
        }
      )
    )
  }

  @Test
  func `Mutating HomomorphMap Updates Language`() {
    var language = Language {
      Grammar(
        Production("expression") {
          Choice {
            "+"
            "*"
          }
        }
      )
    }

    language.homomorphMap { terminal -> Terminal? in
      if terminal == "+" {
        return "-"
      } else {
        return nil
      }
    }

    expectNoDifference(
      language.grammar(),
      Grammar(
        Production("expression") {
          Choice {
            "-"
            "*"
          }
        }
      )
    )
  }
}
