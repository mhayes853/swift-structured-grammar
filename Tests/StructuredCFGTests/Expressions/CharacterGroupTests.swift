import CustomDump
import StructuredCFG
import Testing

@Suite
struct CharacterGroupTests {
  @Test
  func `CharacterGroup Can Be Created From String`() {
    let group = CharacterGroup("[a-zA-Z0-9]")
    expectNoDifference(group.isNegated, false)
  }

  @Test
  func `CharacterGroup Formats As Bracket Notation`() {
    let group = CharacterGroup("[a-zA-Z0-9]")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = grammar.formatted(with: .w3cEbnf)
    #expect(formatted.contains("[a-zA-Z0-9]"))
  }

  @Test
  func `Negated CharacterGroup Has Correct Flag`() {
    let group = CharacterGroup("[^a-z]")
    expectNoDifference(group.isNegated, true)
  }

  @Test
  func `CharacterGroup Negated Method Returns New Instance`() {
    let group = CharacterGroup("[a-z]")
    let negated = group.negated()

    expectNoDifference(group.isNegated, false)
    expectNoDifference(negated.isNegated, true)
  }

  @Test
  func `CharacterGroup Parses Character Range`() {
    let group = CharacterGroup("[a-z]")
    expectNoDifference(group.members.count, 1)
  }

  @Test
  func `CharacterGroup Parses Negated Character Class`() {
    let group = CharacterGroup("[^0-9]")
    expectNoDifference(group.isNegated, true)
  }

  @Test
  func `CharacterGroup Parses Digit Class`() {
    let group = CharacterGroup("[\\d]")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = grammar.formatted(with: .w3cEbnf)
    #expect(formatted.contains("[\\d]"))
  }

  @Test
  func `CharacterGroup Parses Word Class`() {
    let group = CharacterGroup("[\\w]")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = grammar.formatted(with: .w3cEbnf)
    #expect(formatted.contains("[\\w]"))
  }

  @Test
  func `CharacterGroup Parses Whitespace Class`() {
    let group = CharacterGroup("[\\s]")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = grammar.formatted(with: .w3cEbnf)
    #expect(formatted.contains("[\\s]"))
  }

  @Test
  func `CharacterGroup Parses Non-Digit Class`() {
    let group = CharacterGroup("[\\D]")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = grammar.formatted(with: .w3cEbnf)
    #expect(formatted.contains("[\\D]"))
  }

  @Test
  func `CharacterGroup Parses Non-Word Class`() {
    let group = CharacterGroup("[\\W]")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = grammar.formatted(with: .w3cEbnf)
    #expect(formatted.contains("[\\W]"))
  }

  @Test
  func `CharacterGroup Parses Non-Whitespace Class`() {
    let group = CharacterGroup("[\\S]")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = grammar.formatted(with: .w3cEbnf)
    #expect(formatted.contains("[\\S]"))
  }

  @Test
  func `CharacterGroup Parses XML NameStart Class`() {
    let group = CharacterGroup("[\\i]")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = grammar.formatted(with: .w3cEbnf)
    #expect(formatted.contains("[\\i]"))
  }

  @Test
  func `CharacterGroup Parses XML NameChar Class`() {
    let group = CharacterGroup("[\\c]")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = grammar.formatted(with: .w3cEbnf)
    #expect(formatted.contains("[\\c]"))
  }

  @Test
  func `CharacterGroup Parses Newline Escape`() {
    let group = CharacterGroup("[\\n]")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = grammar.formatted(with: .w3cEbnf)
    #expect(formatted.contains("[\\n]"))
  }

  @Test
  func `CharacterGroup Parses Carriage Return Escape`() {
    let group = CharacterGroup("[\\r]")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = grammar.formatted(with: .w3cEbnf)
    #expect(formatted.contains("[\\r]"))
  }

  @Test
  func `CharacterGroup Parses Tab Escape`() {
    let group = CharacterGroup("[\\t]")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = grammar.formatted(with: .w3cEbnf)
    #expect(formatted.contains("[\\t]"))
  }

  @Test
  func `CharacterGroup Formats Combined Character Class`() {
    let group = CharacterGroup("[a-zA-Z0-9_]")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = grammar.formatted(with: .w3cEbnf)
    #expect(formatted.contains("[a-zA-Z0-9_]"))
  }
}
