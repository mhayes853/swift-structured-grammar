import CustomDump
import Testing
import StructuredCFG

@Suite
struct `RepeatExpressionTests` {
  @Test
  func `Exact Repeat Formats In GBNF`() {
    let grammar = Grammar(Rule("start") {
      Repeat(3) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: .gbnf),
      #"start ::= "a"{3}"#
    )
  }

  @Test
  func `At Least Repeat Formats In GBNF`() {
    let grammar = Grammar(Rule("start") {
      Repeat(2...) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: .gbnf),
      #"start ::= "a"{2,}"#
    )
  }

  @Test
  func `At Most Repeat Formats In GBNF`() {
    let grammar = Grammar(Rule("start") {
      Repeat(...4) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: .gbnf),
      #"start ::= "a"{0,4}"#
    )
  }

  @Test
  func `Bounded Repeat Formats In GBNF`() {
    let grammar = Grammar(Rule("start") {
      Repeat(1...3) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: .gbnf),
      #"start ::= "a"{1,3}"#
    )
  }

  @Test
  func `Exact Repeat Expands In W3C EBNF`() {
    let grammar = Grammar(Rule("start") {
      Repeat(3) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: .w3cEbnf),
      #"start ::= "a" "a" "a""#
    )
  }

  @Test
  func `At Least Repeat Expands In W3C EBNF`() {
    let grammar = Grammar(Rule("start") {
      Repeat(2...) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: .w3cEbnf),
      #"start ::= "a" "a" "a"*"#
    )
  }

  @Test
  func `At Most Repeat Expands In W3C EBNF`() {
    let grammar = Grammar(Rule("start") {
      Repeat(...3) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: .w3cEbnf),
      #"start ::= ("a" | "a" "a" | "a" "a" "a")?"#
    )
  }

  @Test
  func `Bounded Repeat Expands In W3C EBNF`() {
    let grammar = Grammar(Rule("start") {
      Repeat(1...3) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: .w3cEbnf),
      #"start ::= "a" ("a" | "a" "a")?"#
    )
  }

  @Test
  func `Repeat With Partial Range Up To Expands In W3C EBNF`() {
    let grammar = Grammar(Rule("start") {
      Repeat(..<3) { "a" }
    })

    expectNoDifference(
      try! grammar.formatted(with: .w3cEbnf),
      #"start ::= ("a" | "a" "a")?"#
    )
  }

  @Test
  func `Repeat With Complex Expression In GBNF`() {
    let grammar = Grammar(Rule("start") {
      Repeat(2) {
        Choice {
          "a"
          "b"
        }
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: .gbnf),
      #"start ::= ("a" | "b"){2}"#
    )
  }

  @Test
  func `Repeat Of Zero Or More Is Zero Or More In W3C`() {
    let grammar = Grammar(Rule("start") {
      Repeat(0...) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: .w3cEbnf),
      #"start ::= "a"*"#
    )
  }

  @Test
  func `Repeat Of Zero Is Empty In W3C`() {
    let grammar = Grammar(Rule("start") {
      Repeat(0) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: .w3cEbnf),
      ""
    )
  }

  @Test
  func `Repeat With Partial Range Up To`() {
    let grammar = Grammar(Rule("start") {
      Repeat(..<3) { "a" }
    })

    expectNoDifference(
      try! grammar.formatted(with: .gbnf),
      #"start ::= "a"{0,2}"#
    )
  }
}
