import Foundation
import Testing

@Suite
struct GrammarValidationTests {
  @Test
  func `Snapshot Grammars Are Valid`() throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["node", "validate-grammars.js"]
    
    let testFileURL = URL(fileURLWithPath: #filePath)
    let testsDir = testFileURL.deletingLastPathComponent()
    let rootDir = testsDir.deletingLastPathComponent().deletingLastPathComponent()
    let validationDir = rootDir.appendingPathComponent("validation")
    
    process.currentDirectoryURL = validationDir

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""

    if process.terminationStatus != 0 {
      Issue.record("Grammar validation failed:\n\(output)")
    }

    #expect(process.terminationStatus == 0)
  }
}
