import CustomDump
import Testing
import StructuredCFG

@Suite
struct `ExpressionBuilder tests` {
  @Test
  func `ConcatanateExpressions Builder Uses Empty Expression For Empty Body`() {
    let expression = ConcatenateExpressions {}.expression
    expectNoDifference(expression, .empty)
  }

  @Test
  func `ConcatanateExpressions Builder Returns Single Child Directly`() {
    let expression = ConcatenateExpressions { "value" }.expression
    expectNoDifference(expression, .terminal("value"))
  }

  @Test
  func `ConcatanateExpressions Builder Concatenates Multiple Children`() {
    let expression = ConcatenateExpressions {
      "value"
      Ref("identifier")
    }.expression
    expectNoDifference(expression, .concat([.terminal("value"), .ref("identifier")]))
  }

  @Test
  func `ConcatanateExpressions Builder Supports Optional Child`() {
    let includeValue = false
    let expression = ConcatenateExpressions {
      if includeValue {
        "value"
      }
    }.expression

    expectNoDifference(expression, .empty)
  }

  @Test
  func `ConcatanateExpressions Builder Supports Conditional Branches`() {
    let includeReference = true
    let expression = ConcatenateExpressions {
      if includeReference {
        Ref("identifier")
      } else {
        "value"
      }
    }.expression

    expectNoDifference(expression, .ref("identifier"))
  }
}
