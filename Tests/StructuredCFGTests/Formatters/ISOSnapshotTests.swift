import CustomDump
import Foundation
@preconcurrency import SnapshotTesting
import StructuredCFG
import Testing

@Suite
struct `ISO Snapshot tests` {
  @Test(arguments: ISOSnapshotSuite.cases.map(\.name))
  func `Representative Grammars Format Canonically`(snapshotName: String) {
    let snapshotCase = ISOSnapshotSuite.snapshotCase(named: snapshotName)
    assertISOEBNFSnapshot(snapshotCase.language.grammar(), named: snapshotCase.name)
  }
}

private let isRecordingISOSnapshots = ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"

private func assertISOEBNFSnapshot(
  _ value: @autoclosure () -> Grammar,
  named name: String,
  testName: String = "Representative Grammars Format Canonically",
  fileID: StaticString = #fileID,
  file: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column,
  formatter: Grammar.ISOIECEBNFFormatter = .isoIecEbnf
) {
  let failure = verifySnapshot(
    of: value(),
    as: .isoIecEbnf(formatter: formatter),
    named: name,
    record: isRecordingISOSnapshots,
    fileID: fileID,
    file: file,
    testName: testName,
    line: line,
    column: column
  )

  if isRecordingISOSnapshots {
    return
  }

  expectNoDifference(failure, nil)
}

private enum ISOSnapshotSuite {
  static let cases = RepresentativeSnapshotLanguageSuite.cases + [
    RepresentativeSnapshotLanguageCase(
      name: "special-sequence-grammar",
      language: Grammar(startingSymbol: "space") {
        Rule("space") {
          Special("ASCII character 32")
        }
        Rule("line") {
          Choice {
            EmptyExpression()
            Ref("space")
          }
        }
      }.language
    )
  ]

  static func snapshotCase(named name: String) -> RepresentativeSnapshotLanguageCase {
    self.cases.first(where: { $0.name == name })!
  }
}
