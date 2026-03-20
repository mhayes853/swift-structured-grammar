import CustomDump
import StructuredCFG
import Testing

@Suite
struct `Terminal tests` {
  @Test
  func `String Terminal Stores String Part`() {
    let terminal = Terminal("ab")

    expectNoDifference(terminal.characters, [.character("a"), .character("b")])
  }

  @Test
  func `Hex Terminal Decodes To Value`() {
    let terminal = Terminal(hex: [
      "A".unicodeScalars.first!,
      "B".unicodeScalars.first!,
      "\t".unicodeScalars.first!
    ])

    expectNoDifference(terminal.string, "AB\t")
  }

  @Test
  func `Mixed Terminal Decodes To Value`() {
    let terminal = Terminal(characters: [.hex("a".unicodeScalars.first!), .character("a")])

    expectNoDifference(terminal.string, "aa")
  }

  @Test
  func `Terminal Stores Explicit Characters`() {
    let terminal = Terminal(characters: [
      .character("a"),
      .character("b"),
      .hex("c".unicodeScalars.first!),
      .unicode("d".unicodeScalars.first!)
    ])

    expectNoDifference(
      terminal.characters,
      [
        .character("a"),
        .character("b"),
        .hex("c".unicodeScalars.first!),
        .unicode("d".unicodeScalars.first!)
      ]
    )
  }

  @Test
  func `Unicode Terminal Decodes To Value`() {
    let terminal = Terminal(unicode: ["A".unicodeScalars.first!])

    expectNoDifference(terminal.string, "A")
  }
}
