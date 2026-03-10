import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `ZeroOrMore tests` {
  @Test
  func `Formats As Repetition`() {
    let grammar = Grammar {
      Production("start") {
        ZeroOrMore {
          "a"
        }
      }
    }

    expectNoDifference(grammar.formatted(), "start = {\"a\"} ;")
  }
}
