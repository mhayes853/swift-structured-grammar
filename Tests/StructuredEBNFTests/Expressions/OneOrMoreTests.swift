import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `OneOrMore tests` {
  @Test
  func `Direct Initialization Lowers To Canonical Concat And Zero Or More`() {
    let expression = OneOrMore { "value" }.expression
    expectNoDifference(expression, .concat([.terminal("value"), .zeroOrMore(.terminal("value"))]))
  }
}
