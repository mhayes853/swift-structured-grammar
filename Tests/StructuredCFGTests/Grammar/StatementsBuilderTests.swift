import CustomDump
import StructuredCFG
import Testing

@Suite
struct `StatementsBuilder tests` {
  @Test
  func `Builds Grammar From Mixed Statements`() {
    let grammar = Grammar(startingSymbol: "start") {
      Comment("Leading comment")
      Rule("start") { "value" }
    }

    expectNoDifference(
      Array(grammar.statements),
      [
        .comment(Comment("Leading comment")),
        .rule(Rule("start") { "value" })
      ]
    )
    expectNoDifference(Array(grammar.rules), [Rule("start") { "value" }])
  }
}
