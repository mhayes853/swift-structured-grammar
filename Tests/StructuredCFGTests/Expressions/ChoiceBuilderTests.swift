import CustomDump
import Testing
import StructuredCFG

@Suite
struct `ChoiceBuilder tests` {
  @Test
  func `Choice Builder Builds Alternatives`() {
    let expression = Choice {
      "value"
      Ref("identifier")
    }.expression

    expectNoDifference(expression, Expression.choice([.terminal("value"), .ref("identifier")]))
  }

  @Test
  func `Choice Builder Accepts Single Alternative`() {
    let expression = Choice { "value" }.expression
    expectNoDifference(expression, Expression.choice([.terminal("value")]))
  }

  @Test
  func `Choice Builder Supports Optional Alternatives`() {
    let includeReference = false
    let expression = Choice {
      "value"
      if includeReference {
        Ref("identifier")
      }
    }.expression

    expectNoDifference(expression, Expression.choice([.terminal("value")]))
  }

  @Test
  func `Choice Builder Supports Conditional Branches`() {
    let useReference = true
    let expression = Choice {
      if useReference {
        Ref("identifier")
      } else {
        "value"
      }
    }.expression

    expectNoDifference(expression, Expression.choice([.ref("identifier")]))
  }
}
