import CustomDump
import StructuredCFG
import Testing

@Suite
struct `CharacterGroup tests` {
  @Test
  func `CharacterGroup Can Be Created From String`() {
    let group = CharacterGroup("a-zA-Z0-9")

    expectNoDifference(group.isNegated, false)
    expectNoDifference(
      group.members ?? [],
      [
        .range(.character("a"), .character("z")),
        .range(.character("A"), .character("Z")),
        .range(.character("0"), .character("9"))
      ]
    )
  }

  @Test
  func `CharacterGroup Formats As Bracket Notation`() throws {
    let group = CharacterGroup("a-zA-Z0-9")

    let grammar = Grammar(startingSymbol: "test") {
      Rule("test") {
        group
      }
    }

    let formatted = try grammar.formatted(with: .w3cEbnf)
    expectNoDifference(formatted, #"test ::= [a-zA-Z\d]"#)
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
    expectNoDifference(group.members ?? [], [.range(.character("a"), .character("z"))])
  }

  @Test
  func `CharacterGroup Parses Negated Character Class`() {
    let group = CharacterGroup("^0-9")
    expectNoDifference(group.isNegated, true)
    expectNoDifference(group.members ?? [], [.range(.character("0"), .character("9"))])
  }

  @Test
  func `CharacterGroup Parses Digit Class`() {
    let group = CharacterGroup("\\d")

    expectNoDifference(group.isDigit, true)
    expectNoDifference(group.members ?? [], [.range(.character("0"), .character("9"))])
  }

  @Test
  func `CharacterGroup Parses Word Class`() {
    let group = CharacterGroup("\\w")

    expectNoDifference(group.isWord, true)
    expectNoDifference(
      group.members ?? [],
      [
        .range(.character("a"), .character("z")),
        .range(.character("A"), .character("Z")),
        .range(.character("0"), .character("9")),
        .character(.character("_"))
      ]
    )
  }

  @Test
  func `CharacterGroup Parses Mixed Canonical Shorthand`() {
    let group = CharacterGroup("\\w\\d")

    expectNoDifference(
      group.members ?? [],
      [
        .range(.character("a"), .character("z")),
        .range(.character("A"), .character("Z")),
        .range(.character("0"), .character("9")),
        .character(.character("_")),
        .range(.character("0"), .character("9"))
      ]
    )
  }

  @Test
  func `CharacterGroup Parses Whitespace Class`() {
    let group = CharacterGroup("\\s")

    expectNoDifference(group.isWhitespace, true)
    expectNoDifference(
      group.members ?? [],
      [
        .character(.character(" ")),
        .escaped(.tab),
        .escaped(.newline),
        .escaped(.carriageReturn)
      ]
    )
  }

  @Test
  func `CharacterGroup Parses NonDigit Class`() {
    let group = CharacterGroup("\\D")

    expectNoDifference(group.isNonDigit, true)
    expectNoDifference(group.isNegated, true)
    expectNoDifference(group.members ?? [], [.range(.character("0"), .character("9"))])
  }

  @Test
  func `CharacterGroup Parses NonWord Class`() {
    let group = CharacterGroup("\\W")

    expectNoDifference(group.isNonWord, true)
    expectNoDifference(group.isNegated, true)
  }

  @Test
  func `CharacterGroup Parses NonWhitespace Class`() {
    let group = CharacterGroup("\\S")

    expectNoDifference(group.isNonWhitespace, true)
    expectNoDifference(group.isNegated, true)
  }

  @Test
  func `CharacterGroup Rejects XML NameStart Class`() {
    #expect(throws: CharacterGroup.ParseError.self) {
      try CharacterGroup(String("\\i"))
    }
  }

  @Test
  func `CharacterGroup Rejects XML NameChar Class`() {
    #expect(throws: CharacterGroup.ParseError.self) {
      try CharacterGroup(String("\\c"))
    }
  }

  @Test
  func `CharacterGroup Rejects Mixed Negated Predefined Class`() {
    #expect(throws: CharacterGroup.ParseError.self) {
      try CharacterGroup(String("a\\D"))
    }
  }

  @Test
  func `CharacterGroup Parses Newline Escape`() {
    let group = CharacterGroup("\\n")
    expectNoDifference(group.members ?? [], [.escaped(.newline)])
  }

  @Test
  func `CharacterGroup Parses Carriage Return Escape`() {
    let group = CharacterGroup("\\r")
    expectNoDifference(group.members ?? [], [.escaped(.carriageReturn)])
  }

  @Test
  func `CharacterGroup Parses Tab Escape`() {
    let group = CharacterGroup("\\t")
    expectNoDifference(group.members ?? [], [.escaped(.tab)])
  }

  @Test
  func `CharacterGroup Parses Escaped Closing Bracket In Unbracketed Group`() {
    let group = CharacterGroup(",\\]")

    expectNoDifference(
      group.members ?? [],
      [
        .character(.character(",")),
        .escaped(.rightBracket)
      ]
    )
  }

  @Test
  func `CharacterGroup Parses Escaped Closing Bracket In Bracketed Group`() throws {
    let group = try CharacterGroup(String("[,\\]]"))

    expectNoDifference(
      group.members ?? [],
      [
        .character(.character(",")),
        .escaped(.rightBracket)
      ]
    )
  }

  @Test
  func `CharacterGroup Formats Combined Character Class`() throws {
    let group = CharacterGroup("a-zA-Z0-9_")

    let grammar = Grammar(startingSymbol: "test") {
      Rule("test") {
        group
      }
    }

    let formatted = try grammar.formatted(with: .w3cEbnf)
    expectNoDifference(formatted, #"test ::= [\w]"#)
  }

  @Test
  func `CharacterGroup Created From ClosedRange Has Correct Members`() {
    let group = CharacterGroup("a"..."z")

    expectNoDifference(group.members ?? [], [.range(.character("a"), .character("z"))])
  }

  @Test
  func `CharacterGroup Parses Hex Character`() {
    let group = CharacterGroup("#x41")

    expectNoDifference(group.members ?? [], [.character(.hex("A".unicodeScalars.first!))])
  }

  @Test
  func `CharacterGroup Parses Hex Character Range`() {
    let group = CharacterGroup("#x41-#x5A")

    expectNoDifference(
      group.members ?? [],
      [.range(.hex("A".unicodeScalars.first!), .hex("Z".unicodeScalars.first!))]
    )
  }

  @Test
  func `CharacterGroup Parses Hex Character With Leading Zeros`() {
    let group = CharacterGroup("#x0041")

    expectNoDifference(group.members ?? [], [.character(.hex("A".unicodeScalars.first!))])
  }

  @Test
  func `CharacterGroup Parses Hex Escape`() {
    let group = CharacterGroup("\\x41")

    expectNoDifference(group.members ?? [], [.character(.hex("A".unicodeScalars.first!))])
  }

  @Test
  func `CharacterGroup Parses Mixed Characters And Hex`() {
    let group = CharacterGroup("a-z#x41")

    expectNoDifference(
      group.members ?? [],
      [.range(.character("a"), .character("z")), .character(.hex("A".unicodeScalars.first!))]
    )
  }

  @Test
  func `CharacterGroup Parses Mixed Characters And HexEscape`() {
    let group = CharacterGroup("a-z\\x41")

    expectNoDifference(
      group.members ?? [],
      [.range(.character("a"), .character("z")), .character(.hex("A".unicodeScalars.first!))]
    )
  }

  @Test
  func `CharacterGroup Rejects Invalid Hex Character`() {
    #expect(throws: CharacterGroup.ParseError.self) {
      try CharacterGroup(String("#xGG"))
    }
  }

  @Test
  func `CharacterGroup Rejects Invalid Hex Escape`() {
    #expect(throws: CharacterGroup.ParseError.self) {
      try CharacterGroup(String("\\xGG"))
    }
  }

  @Test
  func `CharacterGroup Rejects Invalid Hex Range Start Greater Than End`() {
    #expect(throws: CharacterGroup.ParseError.self) {
      try CharacterGroup(String("#x5A-#x41"))
    }
  }

  @Test
  func `Hex CharacterGroup Formats In W3C EBNF`() throws {
    let group = CharacterGroup("#x41")

    let grammar = Grammar(startingSymbol: "test") {
      Rule("test") {
        group
      }
    }

    let formatted = try grammar.formatted(with: .w3cEbnf)
    expectNoDifference(formatted, #"test ::= [#x41]"#)
  }

  @Test
  func `Hex Range CharacterGroup Formats In W3C EBNF`() throws {
    let group = CharacterGroup("#x41-#x5A")

    let grammar = Grammar(startingSymbol: "test") {
      Rule("test") {
        group
      }
    }

    let formatted = try grammar.formatted(with: .w3cEbnf)
    expectNoDifference(formatted, #"test ::= [#x41-#x5a]"#)
  }

  @Test
  func `Hex CharacterGroup Formats In GBNF`() throws {
    let group = CharacterGroup("#x41")

    let grammar = Grammar(startingSymbol: "test") {
      Rule("test") {
        group
      }
    }

    let formatted = try grammar.formatted(with: .gbnf)
    expectNoDifference(formatted, #"test ::= [\x41]"#)
  }

  @Test
  func `CharacterGroup All Formats In GBNF`() throws {
    let group = CharacterGroup.all

    let grammar = Grammar(startingSymbol: "test") {
      Rule("test") {
        group
      }
    }

    let formatted = try grammar.formatted(with: .gbnf)
    expectNoDifference(formatted, #"test ::= [\u0000-\U0010FFFF]"#)
  }

  @Test
  func `CharacterGroup All Does Not Expose Members`() {
    let group = CharacterGroup.all

    expectNoDifference(group.members, nil)
  }

  @Test
  func `CharacterGroup All Sets IsAllCharacters`() {
    let group = CharacterGroup.all

    expectNoDifference(group.isAllCharacters, true)
  }

  @Test
  func `CharacterGroup Negated All Formats In GBNF`() throws {
    let group = CharacterGroup.all.negated()

    let grammar = Grammar(startingSymbol: "test") {
      Rule("test") {
        group
      }
    }

    let formatted = try grammar.formatted(with: .gbnf)
    expectNoDifference(formatted, #"test ::= [^\u0000-\U0010FFFF]"#)
  }

  @Test
  func `CharacterGroup Parses Unicode 4Digit Escape`() {
    let group = CharacterGroup("\\u0041")

    expectNoDifference(
      group.members ?? [],
      [.character(.unicode("A".unicodeScalars.first!))]
    )
  }

  @Test
  func `CharacterGroup Parses Unicode 8Digit Escape`() {
    let group = CharacterGroup("\\U00000041")

    expectNoDifference(
      group.members ?? [],
      [.character(.unicode("A".unicodeScalars.first!))]
    )
  }

  @Test
  func `CharacterGroup Parses Unicode Range`() {
    let group = CharacterGroup("\\u0041-\\U0000005A")

    expectNoDifference(
      group.members ?? [],
      [
        .range(
          .unicode("A".unicodeScalars.first!),
          .unicode("Z".unicodeScalars.first!)
        )
      ]
    )
  }

  @Test
  func `CharacterGroup Parses Mixed Hex And Unicode Range`() {
    let group = CharacterGroup("\\x00-\\U0001FFFF")

    expectNoDifference(
      group.members ?? [],
      [
        .range(
          .hex(Unicode.Scalar(UInt32(0))!),
          .unicode(Unicode.Scalar(UInt32(0x1FFFF))!)
        )
      ]
    )
  }
}
