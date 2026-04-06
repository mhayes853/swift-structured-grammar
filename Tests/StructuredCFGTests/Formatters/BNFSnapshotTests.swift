#if !os(Windows)
import CustomDump
import Foundation
@preconcurrency import SnapshotTesting
import StructuredCFG
import Testing

@Suite
struct `BNF Snapshot tests` {
  @Test(arguments: BNFSnapshotSuite.cases.map { $0.name })
  func `Representative Grammars Format Canonically`(snapshotName: String) {
    let snapshotCase = BNFSnapshotSuite.snapshotCase(named: snapshotName)
    assertBNFSnapshot(snapshotCase.language.grammar(), named: snapshotCase.name)
  }

  @Test
  func `Comments Format Canonically`() {
    let grammar = Grammar(startingSymbol: "start") {
      Comment("A BNF comment")
      Rule("start") { "value" }
    }
    assertBNFSnapshot(grammar, named: "commented-grammar")
  }

  @Test
  func `Comments Format Canonically With Single Line Style`() {
    let grammar = Grammar(startingSymbol: "start") {
      Comment("A BNF comment")
      Rule("start") { "value" }
    }
    assertBNFSnapshot(
      grammar,
      named: "commented-grammar-line-comments",
      formatter: .bnf(commentStyle: .line)
    )
  }
}

private let isRecordingBNFSnapshots = ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"

private func assertBNFSnapshot(
  _ value: @autoclosure () -> Grammar,
  named name: String,
  testName: String = "Representative Grammars Format Canonically",
  fileID: StaticString = #fileID,
  file: StaticString = #filePath,
  function: StaticString = #function,
  line: UInt = #line,
  column: UInt = #column,
  formatter: Grammar.BNFFormatter = .bnf
) {
  let failure = verifySnapshot(
    of: value(),
    as: .bnf(formatter: formatter),
    named: name,
    record: isRecordingBNFSnapshots,
    fileID: fileID,
    file: file,
    testName: testName,
    line: line,
    column: column
  )

  if isRecordingBNFSnapshots {
    return
  }

  expectNoDifference(failure, nil)
}

private enum BNFSnapshotSuite {
  static let unsupportedCaseNames: Set<String> = [
    "character-group-grammar",
    "hex-terminal-grammar",
    "json-grammar"
  ]

  static let cases = RepresentativeSnapshotLanguageSuite.replacingJSONLanguage(
    with: JSON(asciiOnly: true).language
  )
  .filter { !Self.unsupportedCaseNames.contains($0.name) }

  static func snapshotCase(named name: String) -> RepresentativeSnapshotLanguageCase {
    self.cases.first(where: { $0.name == name })!
  }
}
#endif
