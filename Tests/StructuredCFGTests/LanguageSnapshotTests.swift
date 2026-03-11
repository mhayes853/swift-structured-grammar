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
              ConcatanateExpressions {
                "let"
                Ref("identifier")
              }
            }
          }

          Production("identifier") {
            Special("identifier")
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
            Special("computed")
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
          Special("identifier")
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
    )
  ]

  static func snapshotCase(named name: String) -> LanguageSnapshotCase {
    self.cases.first(where: { $0.name == name })!
  }
}
