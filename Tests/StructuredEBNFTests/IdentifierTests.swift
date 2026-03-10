import Testing
import CustomDump
import StructuredEBNF

@Suite
struct `Identifier tests` {
  @Test(arguments: [
    "expression",
    "term",
    "plus-sign",
    "identifier_tail",
    "g1__expression"
  ])
  func `Dynamic Initialization Accepts Valid Identifiers`(rawValue: String) throws {
    let identifier = try Identifier(rawValue)

    expectNoDifference(identifier.rawValue, rawValue)
  }

  @Test(arguments: [
    "",
    "1expression",
    "-expression",
    "_expression",
    "expression value",
    "expression+value"
  ])
  func `Dynamic Initialization Rejects Invalid Identifiers`(rawValue: String) {
    #expect(throws: Identifier.InvalidIdentifierError.self) {
      try Identifier(rawValue)
    }
  }

  @Test(arguments: [
    "expression",
    "plus-sign",
    "g1__expression"
  ])
  func `Raw Representable Initialization Accepts Valid Identifiers`(rawValue: String) {
    let identifier = Identifier(rawValue: rawValue)

    expectNoDifference(identifier?.rawValue, rawValue)
  }
}
