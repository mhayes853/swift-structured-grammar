import CustomDump
import StructuredCFG
import Testing

@Suite
struct `Terminal tests` {
  @Test
  func `String Terminal Stores String Part`() {
    let terminal = Terminal("ab")

    expectNoDifference(terminal.parts, [.string("ab")])
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
    let terminal = Terminal(parts: [.hex(["a".unicodeScalars.first!]), .string("a")])

    expectNoDifference(terminal.string, "aa")
  }

  @Test
  func `Adjacent Parts Are Normalized`() {
    let terminal = Terminal(parts: [
      .string("a"),
      .string("b"),
      .hex(["c".unicodeScalars.first!]),
      .hex(["d".unicodeScalars.first!])
    ])

    expectNoDifference(
      terminal.parts,
      [.string("ab"), .hex(["c".unicodeScalars.first!, "d".unicodeScalars.first!])]
    )
  }

  @Test
  func `character returns character when single character`() {
    let terminal = Terminal("a")
    #expect(terminal.character == "a")
  }

  @Test
  func `character returns nil when multiple characters`() {
    let terminal = Terminal("ab")
    #expect(terminal.character == nil)
  }

  @Test
  func `character returns nil when empty`() {
    let terminal = Terminal("")
    #expect(terminal.character == nil)
  }
}
