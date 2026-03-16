import CustomDump
import Foundation
@preconcurrency import SnapshotTesting
import StructuredCFG
import Testing

@Suite
struct `GBNF Snapshot tests` {
  @Test(arguments: GBNFSnapshotSuite.cases.map(\.name))
  func `Representative Grammars Format Canonically`(snapshotName: String) {
    let snapshotCase = GBNFSnapshotSuite.snapshotCase(named: snapshotName)
    assertGBNFSnapshot(snapshotCase.language.grammar(), named: snapshotCase.name)
  }
}

private let isRecordingSnapshots = ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"

private struct GBNFSnapshotCase: Hashable, Sendable {
  let name: String
  let language: Language
}

private func assertGBNFSnapshot(
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
    as: .gbnf(),
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

private enum GBNFSnapshotSuite {
  static let cases = [
    GBNFSnapshotCase(
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
    GBNFSnapshotCase(
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
    GBNFSnapshotCase(
      name: "namespaced-grammar",
      language: Grammar(startingSymbol: .root) {
        Rule(.root) {
          Choice {
            Ref("ga-expression")
            Ref("gb-expression")
          }
        }

        Rule("ga-expression") {
          Ref("ga-term")
        }

        Rule("ga-term") {
          "left"
        }

        Rule("gb-expression") {
          Ref("gb-term")
        }

        Rule("gb-term") {
          "right"
        }
      }.language
    ),
    GBNFSnapshotCase(
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
    GBNFSnapshotCase(
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
            Ref("ga-qualified")
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

        Rule("padding") {
          EmptyExpression()
        }

        Rule("ga-qualified") {
          "qualified"
        }
      }.language
    ),
    GBNFSnapshotCase(
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
    GBNFSnapshotCase(
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
        Rule("hex-digit") {
          CharacterGroup("0-9a-fA-F")
        }
        Rule("escaped") {
          CharacterGroup("\\n\\r\\t")
        }
      }.language
    ),
    GBNFSnapshotCase(
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

  static func snapshotCase(named name: String) -> GBNFSnapshotCase {
    self.cases.first(where: { $0.name == name })!
  }
}
