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
  func `Dynamic Initialization Accepts Valid Symbols`(rawValue: String) {
    let symbol = Symbol(rawValue)

    expectNoDifference(symbol.rawValue, rawValue)
  }

  @Test(arguments: [
    "expression",
    "plus-sign",
    "g1__expression"
  ])
  func `Raw Representable Initialization Accepts Valid Symbols`(rawValue: String) {
    let symbol = Symbol(rawValue: rawValue)

    expectNoDifference(symbol.rawValue, rawValue)
  }
}
