import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `ExpressionBuilder tests` {
  @Test
  func `Concat Builder Uses Empty Expression For Empty Body`() {
    let expression = Concat {}.expression
    expectNoDifference(expression, .empty)
  }

  @Test
  func `Concat Builder Returns Single Child Directly`() {
    let expression = Concat { "value" }.expression
    expectNoDifference(expression, .terminal("value"))
  }

  @Test
  func `Concat Builder Concatenates Multiple Children`() {
    let expression = Concat {
      "value"
      Ref("identifier")
    }.expression
    expectNoDifference(expression, .concat([.terminal("value"), .ref("identifier")]))
  }

  @Test
  func `Concat Builder Supports Optional Child`() {
    let includeValue = false
    let expression = Concat {
      if includeValue {
        "value"
      }
    }.expression

    expectNoDifference(expression, .empty)
  }

  @Test
  func `Concat Builder Supports Conditional Branches`() {
    let includeReference = true
    let expression = Concat {
      if includeReference {
        Ref("identifier")
      } else {
        "value"
      }
    }.expression

    expectNoDifference(expression, .ref("identifier"))
  }
}
