import CustomDump
import StructuredCFG
import Testing

@Suite
struct CharacterGroupTests {
  @Test
  func `CharacterGroup Can Be Created From String`() {
    let group = CharacterGroup("a-zA-Z0-9")
    expectNoDifference(group.isNegated, false)
  }

  @Test
  func `CharacterGroup Formats As Bracket Notation`() {
    let group = CharacterGroup("a-zA-Z0-9")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = try! grammar.formatted(with: .w3cEbnf)
    expectNoDifference(formatted.contains("a-zA-Z0-9"), true)
  }

  @Test
  func `Negated CharacterGroup Has Correct Flag`() {
    let group = CharacterGroup("^a-z")
    expectNoDifference(group.isNegated, true)
  }

  @Test
  func `CharacterGroup Negated Method Returns New Instance`() {
    let group = CharacterGroup("a-z")
    let negated = group.negated()

    expectNoDifference(group.isNegated, false)
    expectNoDifference(negated.isNegated, true)
  }

  @Test
  func `CharacterGroup Parses Character Range`() {
    let group = CharacterGroup("a-z")
    expectNoDifference(group.members.count, 1)
  }

  @Test
  func `CharacterGroup Parses Negated Character Class`() {
    let group = CharacterGroup("^0-9")
    expectNoDifference(group.isNegated, true)
  }

  @Test
  func `CharacterGroup Parses Digit Class`() {
    let group = CharacterGroup("\\d")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = try! grammar.formatted(with: .w3cEbnf)
    expectNoDifference(formatted.contains("\\d"), true)
  }

  @Test
  func `CharacterGroup Parses Word Class`() {
    let group = CharacterGroup("\\w")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = try! grammar.formatted(with: .w3cEbnf)
    expectNoDifference(formatted.contains("\\w"), true)
  }

  @Test
  func `CharacterGroup Parses Whitespace Class`() {
    let group = CharacterGroup("\\s")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = try! grammar.formatted(with: .w3cEbnf)
    expectNoDifference(formatted.contains("\\s"), true)
  }

  @Test
  func `CharacterGroup Parses Non-Digit Class`() {
    let group = CharacterGroup("\\D")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = try! grammar.formatted(with: .w3cEbnf)
    expectNoDifference(formatted.contains("\\D"), true)
  }

  @Test
  func `CharacterGroup Parses Non-Word Class`() {
    let group = CharacterGroup("\\W")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = try! grammar.formatted(with: .w3cEbnf)
    expectNoDifference(formatted.contains("\\W"), true)
  }

  @Test
  func `CharacterGroup Parses Non-Whitespace Class`() {
    let group = CharacterGroup("\\S")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = try! grammar.formatted(with: .w3cEbnf)
    expectNoDifference(formatted.contains("\\S"), true)
  }

  @Test
  func `CharacterGroup Parses XML NameStart Class`() {
    let group = CharacterGroup("\\i")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = try! grammar.formatted(with: .w3cEbnf)
    expectNoDifference(formatted.contains("\\i"), true)
  }

  @Test
  func `CharacterGroup Parses XML NameChar Class`() {
    let group = CharacterGroup("\\c")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = try! grammar.formatted(with: .w3cEbnf)
    expectNoDifference(formatted.contains("\\c"), true)
  }

  @Test
  func `CharacterGroup Parses Newline Escape`() {
    let group = CharacterGroup("\\n")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = try! grammar.formatted(with: .w3cEbnf)
    expectNoDifference(formatted.contains("\\n"), true)
  }

  @Test
  func `CharacterGroup Parses Carriage Return Escape`() {
    let group = CharacterGroup("\\r")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = try! grammar.formatted(with: .w3cEbnf)
    expectNoDifference(formatted.contains("\\r"), true)
  }

  @Test
  func `CharacterGroup Parses Tab Escape`() {
    let group = CharacterGroup("\\t")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = try! grammar.formatted(with: .w3cEbnf)
    expectNoDifference(formatted.contains("\\t"), true)
  }

  @Test
  func `CharacterGroup Formats Combined Character Class`() {
    let group = CharacterGroup("a-zA-Z0-9_")

    let grammar = Grammar(startingSymbol: "test") {
      Production("test") {
        group
      }
    }

    let formatted = try! grammar.formatted(with: .w3cEbnf)
    expectNoDifference(formatted.contains("a-zA-Z0-9_"), true)
  }
}
