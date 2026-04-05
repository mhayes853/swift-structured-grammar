import CustomDump
import Foundation
import Testing

#if os(macOS) || os(Linux) || os(Windows)
@Suite
struct GrammarValidationTests {
  @Test
  func `NPM Validate Command Succeeds`() throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["npm", "run", "validate"]

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
    expectNoDifference(process.terminationStatus, 0, "npm run validate failed:\n\(output)")
  }
}
#endif
