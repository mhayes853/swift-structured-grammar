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
    let grammar = Grammar(Rule("expression") { "value" })

    expectNoDifference(
      grammar.language.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("expression") }
        Rule("expression") { "value" }
      }
    )
  }

  @Test
  func `Grammar Lift Supports Custom Starting Identifier Without Synthesis`() {
    let grammar = Grammar(Rule("expression") { "value" })

    expectNoDifference(
      grammar.language.grammar(startingSymbol: "entry"),
      Grammar(startingSymbol: "entry") {
        Rule("entry") { Ref("expression") }
        Rule("expression") { "value" }
      }
    )
  }

  @Test
  func `Format Delegates To Grammar Formatting`() {
    let language = Grammar(Rule("expression") { "value" }).language

    expectNoDifference(try! language.formatted(with: .w3cEbnf), """
      root ::= expression
      expression ::= "value"
      """)
  }

  @Test
  func `Grammar Uses Default Root Identifier When Language Synthesizes Start Production`() {
    let language = ConcatenateLanguages {
      Grammar(Rule("expression") { "value" })
      Grammar(Rule("statement") { "other" })
    }
    .language

    expectNoDifference(
      language.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("lastart") }
        Rule("expression") { "value" }
        Rule("statement") { "other" }
        Rule("lastart") {
          Ref("expression")
          Ref("statement")
        }
      }
    )
  }

  @Test
  func `Grammar Supports Custom Starting Identifier`() {
    let language = Union {
      Grammar(Rule("expression") { "value" })
      Grammar(Rule("statement") { "other" })
    }
    .language

    expectNoDifference(
      language.grammar(startingSymbol: "entry"),
      Grammar(startingSymbol: "entry") {
        Rule("entry") { Ref("lastart") }
        Rule("expression") { "value" }
        Rule("statement") { "other" }
        Rule("lastart") {
          ChoiceOf {
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
      Grammar(Rule("expression") { "value" })
    }

    let concatenated = base.concatenated(Grammar(Rule("statement") { "other" }))

    expectNoDifference(
      base.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("expression") }
        Rule("expression") { "value" }
      }
    )
    expectNoDifference(
      concatenated.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("lastart") }
        Rule("expression") { "value" }
        Rule("statement") { "other" }
        Rule("lastart") {
          Ref("expression")
          Ref("statement")
        }
      }
    )
  }

  @Test
  func `Mutating Concatenate Updates Language`() {
    var language = Language {
      Grammar(Rule("expression") { "value" })
    }

    language.concatenate(Grammar(Rule("statement") { "other" }))

    expectNoDifference(
      language.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("lastart") }
        Rule("expression") { "value" }
        Rule("statement") { "other" }
        Rule("lastart") {
          Ref("expression")
          Ref("statement")
        }
      }
    )
  }

  @Test
  func `Unioned Returns New Language Without Mutating Original`() {
    let base = Language {
      Grammar(Rule("expression") { "value" })
    }

    let unioned = base.unioned(Grammar(Rule("statement") { "other" }))

    expectNoDifference(
      base.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("expression") }
        Rule("expression") { "value" }
      }
    )
    expectNoDifference(
      unioned.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("lastart") }
        Rule("expression") { "value" }
        Rule("statement") { "other" }
        Rule("lastart") {
          ChoiceOf {
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
      Grammar(Rule("expression") { "value" })
    }

    language.formUnion(Grammar(Rule("statement") { "other" }))

    expectNoDifference(
      language.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("lastart") }
        Rule("expression") { "value" }
        Rule("statement") { "other" }
        Rule("lastart") {
          ChoiceOf {
            Ref("expression")
            Ref("statement")
          }
        }
      }
    )
  }

  @Test
  func `Starred Returns New Language Without Mutating Original`() {
    let base = Language {
      Grammar(Rule("expression") { "value" })
    }

    let starred = base.starred()

    expectNoDifference(
      base.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("expression") }
        Rule("expression") { "value" }
      }
    )
    expectNoDifference(
      starred.grammar(),
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
  func `Mutating Star Updates Language`() {
    var language = Language {
      Grammar(Rule("expression") { "value" })
    }

    language.formStar()

    expectNoDifference(
      language.grammar(),
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
  func `Reversed Returns New Language Without Mutating Original`() {
    let base = Language {
      Grammar(startingSymbol: "expression") {
        Rule("expression") {
          ConcatenateExpressions {
            "a"
            Ref("term")
          }
        }
        Rule("term") {
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
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("expression") }
        Rule("expression") {
          ConcatenateExpressions {
            "a"
            Ref("term")
          }
        }
        Rule("term") {
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
        Rule(.root) { Ref("expression") }
        Rule("expression") {
          ConcatenateExpressions {
            Ref("term")
            "a"
          }
        }
        Rule("term") {
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
        Rule("expression") {
          ConcatenateExpressions {
            "a"
            Ref("term")
          }
        }
        Rule("term") {
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
        Rule(.root) { Ref("expression") }
        Rule("expression") {
          ConcatenateExpressions {
            Ref("term")
            "a"
          }
        }
        Rule("term") {
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
        Rule("expression") {
          "+"
          Ref("term")
        }
        Rule("term") {
          "+"
        }
      }
    }

    let homomorphed = base.homomorphed("+", to: "-")

    expectNoDifference(
      base.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("expression") }
        Rule("expression") {
          "+"
          Ref("term")
        }
        Rule("term") {
          "+"
        }
      }
    )
    expectNoDifference(
      homomorphed.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("expression") }
        Rule("expression") {
          "-"
          Ref("term")
        }
        Rule("term") {
          "-"
        }
      }
    )
  }

  @Test
  func `Mutating Homomorph Updates Language`() {
    var language = Language {
      Grammar(startingSymbol: "expression") {
        Rule("expression") {
          "+"
          Ref("term")
        }
        Rule("term") {
          "+"
        }
      }
    }

    language.homomorph("+", to: "-")

    expectNoDifference(
      language.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("expression") }
        Rule("expression") {
          "-"
          Ref("term")
        }
        Rule("term") {
          "-"
        }
      }
    )
  }

  @Test
  func `HomomorphMapped Returns New Language Without Mutating Original`() {
    let base = Language {
      Grammar(
        Rule("expression") {
          ChoiceOf {
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
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("expression") }
        Rule("expression") {
          ChoiceOf {
            "+"
            "*"
          }
        }
      }
    )
    expectNoDifference(
      homomorphed.grammar(),
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("expression") }
        Rule("expression") {
          ChoiceOf {
            "-"
            "*"
          }
        }
      }
    )
  }

  @Test
  func `Mutating HomomorphMap Updates Language`() {
    var language = Language {
      Grammar(
        Rule("expression") {
          ChoiceOf {
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
      Grammar(startingSymbol: .root) {
        Rule(.root) { Ref("expression") }
        Rule("expression") {
          ChoiceOf {
            "-"
            "*"
          }
        }
      }
    )
  }

  @Test
  func `Resolved Grammar Preserves Comments Through Nested Language Operations`() {
    let language = ConcatenateLanguages {
      Grammar(startingSymbol: "alpha") {
        Comment("Alpha comment")
        Rule("alpha") { "a" }
      }

      Union {
        Grammar(startingSymbol: "branch") {
          Comment("Left branch comment")
          Rule("branch") { "b" }
        }

        Star {
          Grammar(startingSymbol: "branch") {
            Comment("Right branch comment")
            Rule("branch") { "c" }
          }
        }
      }

      Reverse {
        Grammar(startingSymbol: "tail") {
          Comment("Tail comment")
          Rule("tail") {
            ConcatenateExpressions {
              "d"
              "e"
            }
          }
        }
      }
    }
    .language

    let resolvedGrammar = language.grammar()

    expectNoDifference(
      resolvedGrammar.statements.compactMap { statement in
        guard case .comment(let comment) = statement else { return nil }
        return comment.text
      },
      [
        "Alpha comment",
        "Left branch comment",
        "Right branch comment",
        "Tail comment"
      ]
    )
  }

  @Test
  func `Universal Grammar Matches Any String Including Empty`() async throws {
    let emptyMatch = try await XGrammarTestSupport.matches("", language: .universal)
    let singleCharMatch = try await XGrammarTestSupport.matches("a", language: .universal)
    let multiCharMatch = try await XGrammarTestSupport.matches("hello", language: .universal)

    expectNoDifference(emptyMatch, true)
    expectNoDifference(singleCharMatch, true)
    expectNoDifference(multiCharMatch, true)
  }
}
