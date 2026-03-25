import CustomDump
import StructuredCFG
import Testing

@Suite
struct `Comment Formatting tests` {
  @Test
  func `W3C EBNF Formatter Splits Multiline Comments`() throws {
    let grammar = Grammar(startingSymbol: "start") {
      Comment("First line\nSecond line")
      Rule("start") { "value" }
    }

    expectNoDifference(
      try grammar.formatted(with: .w3cEbnf),
      "/* First line */\n/* Second line */\nstart ::= \"value\""
    )
  }
}
