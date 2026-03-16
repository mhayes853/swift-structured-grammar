import CustomDump
import Foundation
@preconcurrency import SnapshotTesting
import StructuredCFG
import Testing

@Suite
struct `LanguageSnapshot tests` {
  @Test(arguments: LanguageSnapshotSuite.cases.map(\.name))
  func `Representative Grammars Format Canonically`(snapshotName: String) {
    let snapshotCase = LanguageSnapshotSuite.snapshotCase(named: snapshotName)
    assertEBNFSnapshot(snapshotCase.language.grammar(), named: snapshotCase.name)
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
  column: UInt = #column
) {
  let failure = verifySnapshot(
    of: value(),
    as: .ebnf(),
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
            Group {
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
      }.language
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
      }.language
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
      }.language
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
      }.language
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
            Group {
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
      }.language
    ),
    LanguageSnapshotCase(
      name: "json-grammar",
      language: Grammar(startingSymbol: "value") {
        Rule("value") {
          Choice {
            Ref("object")
            Ref("array")
            Ref("string")
            Ref("number")
            "true"
            "false"
            "null"
          }
        }

        Rule("object") {
          "{"
          OptionalExpression {
            Ref("members")
          }
          "}"
        }

        Rule("members") {
          Ref("pair")
          ZeroOrMore {
            Group {
              ","
              Ref("pair")
            }
          }
        }

        Rule("pair") {
          Ref("string")
          ":"
          Ref("value")
        }

        Rule("array") {
          "["
          OptionalExpression {
            Ref("elements")
          }
          "]"
        }

        Rule("elements") {
          Ref("value")
          ZeroOrMore {
            Group {
              ","
              Ref("value")
            }
          }
        }

        Rule("string") {
          "string"
        }

        Rule("number") {
          Ref("integer")
          OptionalExpression {
            Ref("fraction")
          }
          OptionalExpression {
            Ref("exponent")
          }
        }

        Rule("integer") {
          OneOrMore {
            Ref("digit")
          }
        }

        Rule("fraction") {
          "."
          OneOrMore {
            Ref("digit")
          }
        }

        Rule("exponent") {
          Choice {
            "e"
            "E"
          }
          OptionalExpression {
            Ref("sign")
          }
          OneOrMore {
            Ref("digit")
          }
        }

        Rule("sign") {
          Choice {
            "+"
            "-"
          }
        }

        Rule("digit") {
          Choice {
            "0"
            "1"
            "2"
            "3"
            "4"
            "5"
            "6"
            "7"
            "8"
            "9"
          }
        }
      }.language
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
      }.language
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
      }.language
    )
  ]

  static func snapshotCase(named name: String) -> LanguageSnapshotCase {
    self.cases.first(where: { $0.name == name })!
  }
}
