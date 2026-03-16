import CustomDump
import Testing
import StructuredCFG

@Suite
struct `Terminal tests` {
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