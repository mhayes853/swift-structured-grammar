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
        Production("expression") {
          Ref("term")
          ZeroOrMore {
            Choice {
              "+"
              "-"
            }
            Ref("term")
          }
        }

        Production("term") {
          Ref("factor")
          ZeroOrMore {
            Choice {
              "*"
              "/"
            }
            Ref("factor")
          }
        }

        Production("factor") {
          Choice {
            Ref("number")
            Group {
              "("
              Ref("expression")
              ")"
            }
          }
        }

        Production("number") {
          OneOrMore {
            Ref("digit")
          }
        }

        Production("digit") {
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
          Production("expression") {
            Ref("number")
          }

          Production("number") {
            OneOrMore {
              Ref("digit")
            }
          }

          Production("digit") {
            Choice {
              "0"
              "1"
            }
          }
        }

        Grammar(startingSymbol: "statement") {
          Production("statement") {
            Choice {
              "pass"
              ConcatenateExpressions {
                "let"
                Ref("identifier")
              }
            }
          }

          Production("identifier") {
            "identifier"
          }
        }
      }.language
    ),
    LanguageSnapshotCase(
      name: "namespaced-grammar",
      language: Grammar(startingSymbol: .root) {
        Production(.root) {
          Choice {
            Ref("g0__expression")
            Ref("g1__expression")
          }
        }

        Production("g0__expression") {
          Ref("g0__term")
        }

        Production("g0__term") {
          "left"
        }

        Production("g1__expression") {
          Ref("g1__term")
        }

        Production("g1__term") {
          "right"
        }
      }.language
    ),
    LanguageSnapshotCase(
      name: "helper-production-grammar",
      language: KleeneStar {
        Grammar(startingSymbol: "token") {
          Production("token") {
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
        Production("document") {
          Ref("header")
          OneOrMore {
            Ref("assignment")
          }
          OptionalExpression {
            Ref("footer")
          }
        }

        Production("header") {
          "BEGIN"
        }

        Production("assignment") {
          Ref("identifier")
          "="
          Choice {
            Ref("literal")
            Ref("tuple")
            "computed"
          }
        }

        Production("tuple") {
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

        Production("literal") {
          Choice {
            Ref("number")
            Ref("g1__qualified")
            "quoted"
          }
        }

        Production("number") {
          OneOrMore {
            Ref("digit")
          }
        }

        Production("digit") {
          Choice {
            "0"
            "1"
            "2"
          }
        }

        Production("identifier") {
          "identifier"
        }

        Production("footer") {
          "END"
        }

        Production("padding") {
          EmptyExpression()
        }

        Production("g1__qualified") {
          "qualified"
        }
      }.language
    ),
    LanguageSnapshotCase(
      name: "json-grammar",
      language: Grammar(startingSymbol: "value") {
        Production("value") {
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

        Production("object") {
          "{"
          OptionalExpression {
            Ref("members")
          }
          "}"
        }

        Production("members") {
          Ref("pair")
          ZeroOrMore {
            Group {
              ","
              Ref("pair")
            }
          }
        }

        Production("pair") {
          Ref("string")
          ":"
          Ref("value")
        }

        Production("array") {
          "["
          OptionalExpression {
            Ref("elements")
          }
          "]"
        }

        Production("elements") {
          Ref("value")
          ZeroOrMore {
            Group {
              ","
              Ref("value")
            }
          }
        }

        Production("string") {
          "string"
        }

        Production("number") {
          Ref("integer")
          OptionalExpression {
            Ref("fraction")
          }
          OptionalExpression {
            Ref("exponent")
          }
        }

        Production("integer") {
          OneOrMore {
            Ref("digit")
          }
        }

        Production("fraction") {
          "."
          OneOrMore {
            Ref("digit")
          }
        }

        Production("exponent") {
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

        Production("sign") {
          Choice {
            "+"
            "-"
          }
        }

        Production("digit") {
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
        Production("identifier") {
          CharacterGroup("[a-zA-Z_]")
          ZeroOrMore {
            CharacterGroup("[a-zA-Z0-9_]")
          }
        }
        Production("digit") {
          CharacterGroup("[\\d]")
        }
        Production("word") {
          CharacterGroup("[\\w]")
        }
        Production("whitespace") {
          CharacterGroup("[\\s]")
        }
        Production("nonDigit") {
          CharacterGroup("[^\\d]")
        }
        Production("hexDigit") {
          CharacterGroup("[0-9a-fA-F]")
        }
        Production("escaped") {
          CharacterGroup("[\\n\\r\\t]")
        }
      }.language
    ),
    LanguageSnapshotCase(
      name: "range-grammar",
      language: Grammar(startingSymbol: "password") {
        Production("password") {
          Range(2..., Terminal("x"))
        }
        Production("code") {
          Range(4, Terminal("0"))
        }
        Production("upto5") {
          Range(...5, Terminal("a"))
        }
        Production("bounded") {
          Range(1...3, Terminal("b"))
        }
      }.language
    )
  ]

  static func snapshotCase(named name: String) -> LanguageSnapshotCase {
    self.cases.first(where: { $0.name == name })!
  }
}
