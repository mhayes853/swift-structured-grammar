import CustomDump
import Foundation
@preconcurrency import SnapshotTesting
import StructuredCFG
import Testing

@Suite
struct `WirthSnapshot tests` {
  @Test(arguments: WirthSnapshotSuite.cases.map(\.name))
  func `Representative Grammars Format Canonically`(snapshotName: String) {
    let snapshotCase = WirthSnapshotSuite.snapshotCase(named: snapshotName)
    assertWirthEBNFSnapshot(snapshotCase.language.grammar(), named: snapshotCase.name)
  }
}

private let isRecordingSnapshots = ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"

private struct WirthSnapshotCase: Hashable, Sendable {
  let name: String
  let language: Language
}

private func assertWirthEBNFSnapshot(
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
    as: .wirthEbnf(),
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

private enum WirthSnapshotSuite {
  static let cases = [
    WirthSnapshotCase(
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
    WirthSnapshotCase(
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
    WirthSnapshotCase(
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
    WirthSnapshotCase(
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
    WirthSnapshotCase(
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

        Rule("padding") {
          EmptyExpression()
        }

        Rule("g1__qualified") {
          "qualified"
        }
      }.language
    ),
    WirthSnapshotCase(
      name: "hex-terminal-grammar",
      language: Grammar(startingSymbol: "hexOnly") {
        Rule("hexOnly") {
          Terminal(hex: ["A".unicodeScalars.first!, "\t".unicodeScalars.first!])
        }
        Rule("mixed") {
          Terminal(parts: [.hex(["a".unicodeScalars.first!]), .string("a")])
        }
        Rule("surrounded") {
          Terminal(parts: [
            .string("["),
            .hex(["A".unicodeScalars.first!]),
            .string("]")
          ])
        }
      }.language
    ),
    WirthSnapshotCase(
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
    WirthSnapshotCase(
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
        Rule("hexDigit") {
          CharacterGroup("0-9a-fA-F")
        }
        Rule("escaped") {
          CharacterGroup("\\n\\r\\t")
        }
      }.language
    ),
    WirthSnapshotCase(
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
    ),
    WirthSnapshotCase(
      name: "hex-character-group-grammar",
      language: Grammar(startingSymbol: "hex-char") {
        Rule("hex-char") {
          CharacterGroup("#x41")
        }
        Rule("hex-range") {
          CharacterGroup("#x30-#x39")
        }
        Rule("hex-escape") {
          CharacterGroup("\\x41")
        }
        Rule("mixed-hex") {
          CharacterGroup("a-z#x41")
        }
      }.language
    )
  ]

  static func snapshotCase(named name: String) -> WirthSnapshotCase {
    self.cases.first(where: { $0.name == name })!
  }
}
