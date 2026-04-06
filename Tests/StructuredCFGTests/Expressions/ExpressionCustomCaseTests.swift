import CustomDump
import Testing
import StructuredCFG

private struct CustomExpression: Hashable, Sendable {
  let value: String
}

@Suite
struct `Expression custom case tests` {
  @Test
  func `Custom Cases With Same Value Are Equal`() {
    let expr1 = Expression.custom(CustomExpression(value: "test"))
    let expr2 = Expression.custom(CustomExpression(value: "test"))

    expectNoDifference(expr1, expr2)
  }

  @Test
  func `Custom Cases With Different Values Are Not Equal`() {
    let expr1 = Expression.custom(CustomExpression(value: "test1"))
    let expr2 = Expression.custom(CustomExpression(value: "test2"))

    #expect(expr1 != expr2)
  }

  @Test
  func `Custom Cases With Different Types Are Not Equal`() {
    struct OtherCustomExpression: Hashable, Sendable {
      let value: String
    }

    let expr1 = Expression.custom(CustomExpression(value: "test"))
    let expr2 = Expression.custom(OtherCustomExpression(value: "test"))

    #expect(expr1 != expr2)
  }

  @Test
  func `Custom Case Is Not Equal To Other Expression Cases`() {
    let custom = Expression.custom(CustomExpression(value: "test"))
    let terminal = Expression.terminal("test")

    #expect(custom != terminal)
  }

  @Test
  func `Custom Cases With Same Value Have Same Hash`() {
    let expr1 = Expression.custom(CustomExpression(value: "test"))
    let expr2 = Expression.custom(CustomExpression(value: "test"))

    var hasher1 = Hasher()
    expr1.hash(into: &hasher1)
    let hash1 = hasher1.finalize()

    var hasher2 = Hasher()
    expr2.hash(into: &hasher2)
    let hash2 = hasher2.finalize()

    expectNoDifference(hash1, hash2)
  }
}