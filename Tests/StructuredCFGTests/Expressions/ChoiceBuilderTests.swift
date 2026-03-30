import CustomDump
import Testing
import StructuredCFG

@Suite
struct `ChoiceBuilder tests` {
  @Test
  func `Choice Builder Builds Alternatives`() {
    let expression = ChoiceOf {
      "value"
      Ref("identifier")
    }.expression

    expectNoDifference(expression, Expression.choice([.terminal("value"), .ref(Ref("identifier"))]))
  }

  @Test
  func `Choice Builder Accepts Single Alternative`() {
    let expression = ChoiceOf { "value" }.expression
    expectNoDifference(expression, Expression.choice([.terminal("value")]))
  }

  @Test
  func `Choice Builder Supports Optional Alternatives`() {
    let includeReference = false
    let expression = ChoiceOf {
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
    let expression = ChoiceOf {
      if useReference {
        Ref("identifier")
      } else {
        "value"
      }
    }.expression

    expectNoDifference(expression, Expression.choice([.ref(Ref("identifier"))]))
  }
}
