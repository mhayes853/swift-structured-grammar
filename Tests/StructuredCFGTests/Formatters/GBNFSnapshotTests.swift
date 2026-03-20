import CustomDump
import Foundation
@preconcurrency import SnapshotTesting
import StructuredCFG
import Testing

@Suite
struct `GBNF Snapshot tests` {
  @Test(arguments: RepresentativeSnapshotLanguageSuite.cases.map(\.name))
  func `Representative Grammars Format Canonically`(snapshotName: String) {
    let snapshotCase = RepresentativeSnapshotLanguageSuite.snapshotCase(named: snapshotName)
    assertGBNFSnapshot(snapshotCase.language.grammar(), named: snapshotCase.name)
  }

  @Test
  func `Unicode Ranges Format Canonically`() {
    let grammar = Grammar(startingSymbol: "unicode-char") {
      Rule("unicode-char") {
        Ref("unicode-4digit")
      }
      Rule("unicode-4digit") {
        CharacterGroup("\\u0041")
      }
      Rule("unicode-8digit") {
        CharacterGroup("\\U00000041")
      }
      Rule("unicode-range") {
        CharacterGroup("\\u0041-\\U0000005A")
      }
      Rule("all-chars") {
        CharacterGroup.all
      }
    }
    assertGBNFSnapshot(grammar, named: "unicode-range-grammar")
  }
}

private let isRecordingSnapshots = ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"

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
