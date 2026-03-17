import CustomDump
import Testing
import StructuredCFG

@Suite
struct `ISOEBNFFormatter tests` {
  @Test
  func `Formats Semantic Epsilon As Empty Right Hand Side`() throws {
    let grammar = Grammar(Rule("start") {
      EmptyExpression()
    })

    expectNoDifference(try grammar.formatted(with: .isoEbnf), "start = ;")
  }

  @Test
  func `Formats Special Sequence`() throws {
    let grammar = Grammar(Rule("space") {
      Special("ASCII character 32")
    })

    expectNoDifference(try grammar.formatted(with: .isoEbnf), "space = ? ASCII character 32 ?;")
  }

  @Test
  func `Uses Configurable Definition Separator Terminator And Quoting`() throws {
    let grammar = Grammar(Rule("start") {
      Choice {
        EmptyExpression()
        "a"
      }
    })

    expectNoDifference(
      try grammar.formatted(with: .isoEbnf(definitionSeparator: .slash, terminator: .period, quoting: .double)),
      #"start =  / "a"."#
    )
  }

  @Test
  func `Hex Terminals Decode To Ordinary ISO Terminals`() throws {
    let grammar = Grammar(Rule("start") {
      Terminal(parts: [.hex(["a".unicodeScalars.first!]), .string("a")])
    })

    expectNoDifference(try grammar.formatted(with: .isoEbnf), #"start = 'aa';"#)
  }

  @Test
  func `At Most Repeat Uses Empty And Bare Expression Shortcuts`() throws {
    let grammar = Grammar(Rule("start") {
      Repeat(...2) {
        Choice {
          "a"
          "b"
        }
      }
    })

    expectNoDifference(
      try grammar.formatted(with: .isoEbnf),
      #"start =  | ('a' | 'b') | 2 * ('a' | 'b');"#
    )
  }

  @Test
  func `Bounded Repeat Uses Shortcut Optional Tail`() throws {
    let grammar = Grammar(Rule("start") {
      Repeat(1...3) {
        "b"
      }
    })

    expectNoDifference(
      try grammar.formatted(with: .isoEbnf),
      #"start = 'b', ['b' | 2 * 'b'];"#
    )
  }
}
