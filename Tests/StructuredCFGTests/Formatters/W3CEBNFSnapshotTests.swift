import CustomDump
import Foundation
@preconcurrency import SnapshotTesting
import StructuredCFG
import Testing

@Suite
struct `W3CEBNFSnapshot tests` {
  @Test(arguments: LanguageSnapshotSuite.cases.map(\.name))
  func `Representative Grammars Format Canonically`(snapshotName: String) {
    let snapshotCase = LanguageSnapshotSuite.snapshotCase(named: snapshotName)
    let grammar = snapshotCase.language.grammar()
    assertEBNFSnapshot(grammar, named: snapshotCase.name)
  }

  @Test
  func `Comments Format Canonically`() {
    let grammar = Grammar(startingSymbol: "start") {
      Comment("A W3C comment")
      Rule("start") { "value" }
    }
    assertEBNFSnapshot(grammar, named: "commented-grammar")
  }

  @Test
  func `Comments Format Canonically With ISO Style`() {
    let grammar = Grammar(startingSymbol: "start") {
      Comment("A W3C comment")
      Rule("start") { "value" }
    }
    assertEBNFSnapshot(
      grammar,
      named: "commented-grammar-iso-comments",
      formatter: .w3cEbnf(commentStyle: .iso)
    )
  }

  @Test
  func `Representative Grammars Format Canonically With Single Quotes`() {
    var formatter = Grammar.W3CEBNFFormatter()
    formatter.quoting = .single
    let grammar = Grammar(startingSymbol: "expression") {
      Rule("expression") {
        Choice {
          "a"
          "b"
        }
      }
    }
    assertEBNFSnapshot(grammar, named: "single-quote-test", formatter: formatter)
  }

  @Test
  func `All Character Groups Format Canonically`() {
    let grammar = Grammar(startingSymbol: "allchars") {
      Rule("allchars") {
        CharacterGroup.all
      }
      Rule("notallchars") {
        CharacterGroup.all.negated()
      }
    }

    assertEBNFSnapshot(grammar, named: "all-character-group-grammar")
  }
}

private let isRecordingSnapshots = ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"

private struct LanguageSnapshotCase: Hashable, Sendable {
  let name: String
  let language: Language
}

private func assertEBNFSnapshot(
  _ value: @autoclosure () -> Grammar,
  named name: String,
  testName: String = "Representative Grammars Format Canonically",
  fileID: StaticString = #fileID,
  file: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column,
  formatter: Grammar.W3CEBNFFormatter = .w3cEbnf
) {
  let failure = verifySnapshot(
    of: value(),
    as: .ebnf(formatter: formatter),
    named: name,
    record: isRecordingSnapshots,
    fileID: fileID,
    file: file,
    testName: testName,
    line: line,
    column: column
  )

  if isRecordingSnapshots {
    return
  }

  expectNoDifference(failure, nil)
}

private enum LanguageSnapshotSuite {
  static let cases = [
    LanguageSnapshotCase(
      name: "arithmetic-grammar",
      language: Grammar(startingSymbol: "expression") {
        Rule("expression") {
          Ref("term")
          ZeroOrMore {
            Choice {
              "+"
              "-"
            }
            Ref("term")
          }
        }

        Rule("term") {
          Ref("factor")
          ZeroOrMore {
            Choice {
              "*"
              "/"
            }
            Ref("factor")
          }
        }

        Rule("factor") {
          Choice {
            Ref("number")
            GroupExpression {
              "("
              Ref("expression")
              ")"
            }
          }
        }

        Rule("number") {
          OneOrMore {
            Ref("digit")
          }
        }

        Rule("digit") {
          Choice {
            "0"
            "1"
            "2"
          }
        }
      }
      .language
    ),
    LanguageSnapshotCase(
      name: "unioned-grammar",
      language: Union {
        Grammar(startingSymbol: "expression") {
          Rule("expression") {
            Ref("number")
          }

          Rule("number") {
            OneOrMore {
              Ref("digit")
            }
          }

          Rule("digit") {
            Choice {
              "0"
              "1"
            }
          }
        }

        Grammar(startingSymbol: "statement") {
          Rule("statement") {
            Choice {
              "pass"
              ConcatenateExpressions {
                "let"
                Ref("identifier")
              }
            }
          }

          Rule("identifier") {
            "identifier"
          }
        }
      }
      .language
    ),
    LanguageSnapshotCase(
      name: "namespaced-grammar",
      language: Grammar(startingSymbol: .root) {
        Rule(.root) {
          Choice {
            Ref("g0__expression")
            Ref("g1__expression")
          }
        }

        Rule("g0__expression") {
          Ref("g0__term")
        }

        Rule("g0__term") {
          "left"
        }

        Rule("g1__expression") {
          Ref("g1__term")
        }

        Rule("g1__term") {
          "right"
        }
      }
      .language
    ),
    LanguageSnapshotCase(
      name: "helper-production-grammar",
      language: KleeneStar {
        Grammar(startingSymbol: "token") {
          Rule("token") {
            Choice {
              "a"
              "b"
            }
          }
        }
      }
      .language
    ),
    LanguageSnapshotCase(
      name: "concatenated-grammar",
      language: ConcatenateLanguages {
        Grammar(startingSymbol: "prefix") {
          Rule("prefix") {
            "a"
          }
        }

        Grammar(startingSymbol: "suffix") {
          Rule("suffix") {
            "b"
          }
        }
      }
      .language
    ),
    LanguageSnapshotCase(
      name: "reversed-grammar",
      language: Reverse {
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
      .language
    ),
    LanguageSnapshotCase(
      name: "comprehensive-grammar",
      language: Grammar(startingSymbol: "document") {
        Rule("document") {
          Ref("header")
          OneOrMore {
            Ref("assignment")
          }
          OptionalExpression {
            Ref("footer")
          }
        }

        Rule("header") {
          "BEGIN"
        }

        Rule("assignment") {
          Ref("identifier")
          "="
          Choice {
            Ref("literal")
            Ref("tuple")
            "computed"
          }
        }

        Rule("tuple") {
          "("
          Ref("literal")
          ZeroOrMore {
            GroupExpression {
              ","
              Ref("literal")
            }
          }
          ")"
        }

        Rule("literal") {
          Choice {
            Ref("number")
            Ref("g1__qualified")
            "quoted"
          }
        }

        Rule("number") {
          OneOrMore {
            Ref("digit")
          }
        }

        Rule("digit") {
          Choice {
            "0"
            "1"
            "2"
          }
        }

        Rule("identifier") {
          "identifier"
        }

        Rule("footer") {
          "END"
        }

        Rule("g1__qualified") {
          "qualified"
        }
      }
      .language
    ),
    LanguageSnapshotCase(
      name: "json-grammar",
      language: JSON().language
    ),
    LanguageSnapshotCase(
      name: "character-group-grammar",
      language: Grammar(startingSymbol: "identifier") {
        Rule("identifier") {
          CharacterGroup("a-zA-Z_")
          ZeroOrMore {
            CharacterGroup("a-zA-Z0-9_")
          }
        }
        Rule("digit") {
          CharacterGroup("\\d")
        }
        Rule("word") {
          CharacterGroup("\\w")
        }
        Rule("whitespace") {
          CharacterGroup("\\s")
        }
        Rule("nonDigit") {
          CharacterGroup("^\\d")
        }
        Rule("hexDigit") {
          CharacterGroup("0-9a-fA-F")
        }
        Rule("escaped") {
          CharacterGroup("\\n\\r\\t")
        }
      }
      .language
    ),
    LanguageSnapshotCase(
      name: "range-grammar",
      language: Grammar(startingSymbol: "password") {
        Rule("password") {
          Repeat(2..., Terminal("x"))
        }
        Rule("code") {
          Repeat(4, Terminal("0"))
        }
        Rule("upto5") {
          Repeat(...5, Terminal("a"))
        }
        Rule("bounded") {
          Repeat(1...3, Terminal("b"))
        }
      }
      .language
    ),
    LanguageSnapshotCase(
      name: "hex-character-group-grammar",
      language: Grammar(startingSymbol: "hexChar") {
        Rule("hexChar") {
          CharacterGroup("#x41")
        }
        Rule("hexRange") {
          CharacterGroup("#x30-#x39")
        }
        Rule("hexEscape") {
          CharacterGroup("\\x41")
        }
        Rule("mixedHex") {
          CharacterGroup("a-z#x41")
        }
      }
      .language
    ),
    LanguageSnapshotCase(
      name: "hex-terminal-grammar",
      language: Grammar(startingSymbol: "hexOnly") {
        Rule("hexOnly") {
          Terminal(hex: ["A".unicodeScalars.first!, "\t".unicodeScalars.first!])
        }
        Rule("mixed") {
          Terminal(characters: [.hex("a".unicodeScalars.first!), .character("a")])
        }
        Rule("surrounded") {
          Terminal(characters: [
            .character("["),
            .hex("A".unicodeScalars.first!),
            .character("]")
          ])
        }
      }
      .language
    )
  ]

  static func snapshotCase(named name: String) -> LanguageSnapshotCase {
    self.cases.first(where: { $0.name == name })!
  }
}
