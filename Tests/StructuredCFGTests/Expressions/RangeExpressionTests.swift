import CustomDump
import Testing
import StructuredCFG

@Suite
struct `RangeExpressionTests` {
  @Test
  func `Exact Range Formats In GBNF`() {
    let grammar = Grammar(Production("start") {
      Range(exactly: 3, Terminal("a"))
    })

    expectNoDifference(
      grammar.formatted(with: Grammar.GBNFFormatter()),
      #"start ::= "a"{3}"#
    )
  }

  @Test
  func `At Least Range Formats In GBNF`() {
    let grammar = Grammar(Production("start") {
      Range(2..., Terminal("a"))
    })

    expectNoDifference(
      grammar.formatted(with: Grammar.GBNFFormatter()),
      #"start ::= "a"{2,}"#
    )
  }

  @Test
  func `At Most Range Formats In GBNF`() {
    let grammar = Grammar(Production("start") {
      Range(...4, Terminal("a"))
    })

    expectNoDifference(
      grammar.formatted(with: Grammar.GBNFFormatter()),
      #"start ::= "a"{4}"#
    )
  }

  @Test
  func `Bounded Range Formats In GBNF`() {
    let grammar = Grammar(Production("start") {
      Range(1...3, Terminal("a"))
    })

    expectNoDifference(
      grammar.formatted(with: Grammar.GBNFFormatter()),
      #"start ::= "a"{1,3}"#
    )
  }

  @Test
  func `Exact Range Expands In W3C EBNF`() {
    let grammar = Grammar(Production("start") {
      Range(exactly: 3, Terminal("a"))
    })

    expectNoDifference(
      grammar.formatted(with: Grammar.W3CEBNFFormatter()),
      #"start ::= "a" "a" "a""#
    )
  }

  @Test
  func `At Least Range Expands In W3C EBNF`() {
    let grammar = Grammar(Production("start") {
      Range(2..., Terminal("a"))
    })

    expectNoDifference(
      grammar.formatted(with: Grammar.W3CEBNFFormatter()),
      #"start ::= "a" "a" "a"*"#
    )
  }

  @Test
  func `At Most Range Expands In W3C EBNF`() {
    let grammar = Grammar(Production("start") {
      Range(...3, Terminal("a"))
    })

    expectNoDifference(
      grammar.formatted(with: Grammar.W3CEBNFFormatter()),
      #"start ::= "a" | "a" "a" | "a" "a" "a""#
    )
  }

  @Test
  func `Bounded Range Expands In W3C EBNF`() {
    let grammar = Grammar(Production("start") {
      Range(1...3, Terminal("a"))
    })

    expectNoDifference(
      grammar.formatted(with: Grammar.W3CEBNFFormatter()),
      #"start ::= "a" ("a" | "a" "a")?"#
    )
  }

  @Test
  func `Exact Range Expands In Wirth EBNF`() {
    let grammar = Grammar(Production("start") {
      Range(exactly: 3, Terminal("a"))
    })

    expectNoDifference(
      grammar.formatted(with: Grammar.WirthEBNFFormatter()),
      #"start = 'a' 'a' 'a' ."#
    )
  }

  @Test
  func `At Least Range Expands In Wirth EBNF`() {
    let grammar = Grammar(Production("start") {
      Range(2..., Terminal("a"))
    })

    expectNoDifference(
      grammar.formatted(with: Grammar.WirthEBNFFormatter()),
      #"start = 'a' 'a' {'a'} ."#
    )
  }

  @Test
  func `At Most Range Expands In Wirth EBNF`() {
    let grammar = Grammar(Production("start") {
      Range(...3, Terminal("a"))
    })

    expectNoDifference(
      grammar.formatted(with: Grammar.WirthEBNFFormatter()),
      #"start = 'a' | 'a' 'a' | 'a' 'a' 'a' ."#
    )
  }

  @Test
  func `Bounded Range Expands In Wirth EBNF`() {
    let grammar = Grammar(Production("start") {
      Range(1...3, Terminal("a"))
    })

    expectNoDifference(
      grammar.formatted(with: Grammar.WirthEBNFFormatter()),
      #"start = 'a' (['a' | 'a' 'a']) ."#
    )
  }

  @Test
  func `Range With Complex Expression In GBNF`() {
    let grammar = Grammar(Production("start") {
      Range(exactly: 2, Choice {
        Terminal("a")
        Terminal("b")
      })
    })

    expectNoDifference(
      grammar.formatted(with: Grammar.GBNFFormatter()),
      #"start ::= ("a" | "b"){2}"#
    )
  }

  @Test
  func `Range Of Zero Or More Is Zero Or More In W3C`() {
    let grammar = Grammar(Production("start") {
      Range(0..., Terminal("a"))
    })

    expectNoDifference(
      grammar.formatted(with: Grammar.W3CEBNFFormatter()),
      #"start ::= "a"*"#
    )
  }

  @Test
  func `Range Of Zero Is Empty In W3C`() {
    let grammar = Grammar(Production("start") {
      Range(0, Terminal("a"))
    })

    expectNoDifference(
      grammar.formatted(with: Grammar.W3CEBNFFormatter()),
      ""
    )
  }

  @Test
  func `Range With Partial Range Up To`() {
    let grammar = Grammar(Production("start") {
      Range(..<3, Terminal("a"))
    })

    expectNoDifference(
      grammar.formatted(with: Grammar.GBNFFormatter()),
      #"start ::= "a"{2}"#
    )
  }
}
