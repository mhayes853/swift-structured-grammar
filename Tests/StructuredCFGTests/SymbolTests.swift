import Testing
import CustomDump
import StructuredCFG

@Suite
struct `Symbol tests` {
  @Test(arguments: [
    "expression",
    "term",
    "plus-sign",
    "identifier_tail",
    "g1__expression"
  ])
  func `Dynamic Initialization Accepts Valid Symbols`(rawValue: String) throws {
    let symbol = try Symbol(rawValue)

    expectNoDifference(symbol.rawValue, rawValue)
  }

  @Test(arguments: [
    "",
    "1expression",
    "-expression",
    "_expression",
    "expression value",
    "expression+value"
  ])
  func `Dynamic Initialization Rejects Invalid Symbols`(rawValue: String) {
    #expect(throws: Symbol.InvalidSymbolError.self) {
      try Symbol(rawValue)
    }
  }

  @Test(arguments: [
    "expression",
    "plus-sign",
    "g1__expression"
  ])
  func `Raw Representable Initialization Accepts Valid Symbols`(rawValue: String) {
    let symbol = Symbol(rawValue: rawValue)

    expectNoDifference(symbol?.rawValue, rawValue)
  }
}
