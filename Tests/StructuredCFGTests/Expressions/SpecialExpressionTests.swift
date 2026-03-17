import CustomDump
import Testing
import StructuredCFG

@Suite
struct `SpecialExpression tests` {
  @Test
  func `Special Converts To Expression`() {
    expectNoDifference(Special("whitespace").expression, Expression.special(Special("whitespace")))
  }

  @Test
  func `Special Supports String Literal`() {
    let special: Special = "ASCII character 32"

    expectNoDifference(special, Special("ASCII character 32"))
  }
}
