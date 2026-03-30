import CustomDump
import Testing
import StructuredCFG

@Suite
struct `ISOIECEBNFFormatter tests` {
  @Test
  func `Formats Pure Epsilon As An Exact Zero Repeat`() throws {
    let grammar = Grammar(Rule("start") {
      Epsilon()
    })

    expectNoDifference(try grammar.formatted(with: .isoIecEbnf), #"start = 0 * "";"#)
  }

  @Test
  func `Formats Special Sequence`() throws {
    let grammar = Grammar(Rule("space") {
      Special("ASCII character 32")
    })

    expectNoDifference(try grammar.formatted(with: .isoIecEbnf), "space = ? ASCII character 32 ?;")
  }

  @Test
  func `Formats Semantic Epsilon Choice As An Optional Sequence`() throws {
    let grammar = Grammar(Rule("line") {
      ChoiceOf {
        Epsilon()
        Ref("space")
      }
    })

    expectNoDifference(try grammar.formatted(with: .isoIecEbnf), "line = [space];")
  }

  @Test
  func `Uses Configurable Definition Separator Terminator And Quoting`() throws {
    let grammar = Grammar(Rule("start") {
      ChoiceOf {
        Epsilon()
        "a"
      }
    })

    expectNoDifference(
      try grammar.formatted(with: .isoIecEbnf(definitionSeparator: .slash, terminator: .period, quoting: .double)),
      #"start = ["a"]."#
    )
  }

  @Test
  func `Hex Terminals Decode To Ordinary ISO Terminals`() throws {
    let grammar = Grammar(Rule("start") {
      Terminal(characters: [.hex("a".unicodeScalars.first!), .character("a")])
    })

    expectNoDifference(try grammar.formatted(with: .isoIecEbnf), #"start = "aa";"#)
  }

  @Test
  func `At Most Repeat Uses Empty And Bare Expression Shortcuts`() throws {
    let grammar = Grammar(Rule("start") {
      Repeat(...2) {
        ChoiceOf {
          "a"
          "b"
        }
      }
    })

    expectNoDifference(
      try grammar.formatted(with: .isoIecEbnf),
      #"start = [("a" | "b") | 2 * ("a" | "b")];"#
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
      try grammar.formatted(with: .isoIecEbnf),
      #"start = "b", ["b" | 2 * "b"];"#
    )
  }

  @Test
  func `Escapes Control Characters In Terminals`() throws {
    let grammar = Grammar(Rule("whitespace") {
      ChoiceOf {
        "\n"
        "\r"
        "\t"
      }
    })

    expectNoDifference(
      try grammar.formatted(with: .isoIecEbnf),
      #"whitespace = "\n" | "\r" | "\t";"#
    )
  }

  @Test
  func `Normalizes Non ISO Meta Identifiers`() throws {
    let grammar = Grammar(startingSymbol: "hex-char") {
      Rule("hex-char") {
        Ref("ga-term")
      }

      Rule("ga-term") {
        "A"
      }
    }

    expectNoDifference(
      try grammar.formatted(with: .isoIecEbnf),
      #"""
      hexchar = gaterm;
      gaterm = "A";
      """#
    )
  }

  @Test
  func `Formats Quote And Slash Characters Without Special Sequences`() throws {
    let grammar = Grammar(Rule("start") {
      ChoiceOf {
        "/"
        #"""#
        "'"
        #"\"#
      }
    })

    expectNoDifference(
      try grammar.formatted(with: .isoIecEbnf),
      #"start = "/" | '"' | "'" | "\";"#
    )
  }

  @Test
  func `Formatting All Character Group Throws`() {
    let grammar = Grammar(Rule("start") {
      CharacterGroup.all
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .isoIecEbnf)
    }
  }
}
