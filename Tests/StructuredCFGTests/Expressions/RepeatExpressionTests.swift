import CustomDump
import Testing
import StructuredCFG

@Suite
struct `RepeatExpressionTests` {
  @Test
  func `Exact Repeat Formats In GBNF`() {
    let grammar = Grammar(Production("start") {
      Repeat(3) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: Grammar.GBNFFormatter()),
      #"start ::= "a"{3}"#
    )
  }

  @Test
  func `At Least Repeat Formats In GBNF`() {
    let grammar = Grammar(Production("start") {
      Repeat(2...) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: Grammar.GBNFFormatter()),
      #"start ::= "a"{2,}"#
    )
  }

  @Test
  func `At Most Repeat Formats In GBNF`() {
    let grammar = Grammar(Production("start") {
      Repeat(...4) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: Grammar.GBNFFormatter()),
      #"start ::= "a"{4}"#
    )
  }

  @Test
  func `Bounded Repeat Formats In GBNF`() {
    let grammar = Grammar(Production("start") {
      Repeat(1...3) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: Grammar.GBNFFormatter()),
      #"start ::= "a"{1,3}"#
    )
  }

  @Test
  func `Exact Repeat Expands In W3C EBNF`() {
    let grammar = Grammar(Production("start") {
      Repeat(3) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: Grammar.W3CEBNFFormatter()),
      #"start ::= "a" "a" "a""#
    )
  }

  @Test
  func `At Least Repeat Expands In W3C EBNF`() {
    let grammar = Grammar(Production("start") {
      Repeat(2...) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: Grammar.W3CEBNFFormatter()),
      #"start ::= "a" "a" "a"*"#
    )
  }

  @Test
  func `At Most Repeat Expands In W3C EBNF`() {
    let grammar = Grammar(Production("start") {
      Repeat(...3) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: Grammar.W3CEBNFFormatter()),
      #"start ::= "a" | "a" "a" | "a" "a" "a""#
    )
  }

  @Test
  func `Bounded Repeat Expands In W3C EBNF`() {
    let grammar = Grammar(Production("start") {
      Repeat(1...3) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: Grammar.W3CEBNFFormatter()),
      #"start ::= "a" ("a" | "a" "a")?"#
    )
  }

  @Test
  func `Exact Repeat Expands In Wirth EBNF`() {
    let grammar = Grammar(Production("start") {
      Repeat(3) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: Grammar.WirthEBNFFormatter()),
      #"start = 'a' 'a' 'a' ."#
    )
  }

  @Test
  func `At Least Repeat Expands In Wirth EBNF`() {
    let grammar = Grammar(Production("start") {
      Repeat(2...) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: Grammar.WirthEBNFFormatter()),
      #"start = 'a' 'a' {'a'} ."#
    )
  }

  @Test
  func `At Most Repeat Expands In Wirth EBNF`() {
    let grammar = Grammar(Production("start") {
      Repeat(...3) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: Grammar.WirthEBNFFormatter()),
      #"start = 'a' | 'a' 'a' | 'a' 'a' 'a' ."#
    )
  }

  @Test
  func `Bounded Repeat Expands In Wirth EBNF`() {
    let grammar = Grammar(Production("start") {
      Repeat(1...3) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: Grammar.WirthEBNFFormatter()),
      #"start = 'a' (['a' | 'a' 'a']) ."#
    )
  }

  @Test
  func `Repeat With Complex Expression In GBNF`() {
    let grammar = Grammar(Production("start") {
      Repeat(2) {
        Choice {
          "a"
          "b"
        }
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: Grammar.GBNFFormatter()),
      #"start ::= ("a" | "b"){2}"#
    )
  }

  @Test
  func `Repeat Of Zero Or More Is Zero Or More In W3C`() {
    let grammar = Grammar(Production("start") {
      Repeat(0...) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: Grammar.W3CEBNFFormatter()),
      #"start ::= "a"*"#
    )
  }

  @Test
  func `Repeat Of Zero Is Empty In W3C`() {
    let grammar = Grammar(Production("start") {
      Repeat(0) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: Grammar.W3CEBNFFormatter()),
      ""
    )
  }

  @Test
  func `Repeat With Partial Range Up To`() {
    let grammar = Grammar(Production("start") {
      Repeat(..<3) {
        "a"
      }
    })

    expectNoDifference(
      try! grammar.formatted(with: Grammar.GBNFFormatter()),
      #"start ::= "a"{2}"#
    )
  }
}
