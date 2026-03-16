import CustomDump
import Foundation
import Testing

@Suite
struct `Foundation Import tests` {
  @Test
  func `Production Sources Do Not Import Foundation`() throws {
    let rootDirectoryURL = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
    let sourcesDirectoryURL = rootDirectoryURL.appendingPathComponent("Sources")

    let sourceFileURLs = FileManager.default
      .enumerator(
        at: sourcesDirectoryURL,
        includingPropertiesForKeys: nil
      )?
      .compactMap { $0 as? URL }
      .filter { $0.pathExtension == "swift" } ?? []

    let filesImportingFoundation = try sourceFileURLs.compactMap { fileURL in
      let contents = try String(contentsOf: fileURL, encoding: .utf8)
      return contents
        .split(separator: "\n", omittingEmptySubsequences: false)
        .contains { line in
          line.trimmingCharacters(in: .whitespacesAndNewlines) == "import Foundation"
        }
        ? fileURL.path.replacingOccurrences(of: rootDirectoryURL.path + "/", with: "")
        : nil
    }

    expectNoDifference(filesImportingFoundation, [])
  }
}
