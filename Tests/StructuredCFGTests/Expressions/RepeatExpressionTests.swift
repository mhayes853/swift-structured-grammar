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
        ChoiceOf {
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
  func `Repeat Of Zero Throws In W3C`() {
    let grammar = Grammar(Rule("start") {
      Repeat(0) {
        "a"
      }
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .w3cEbnf)
    }
  }

  @Test
  func `Repeat Of Up To Zero Throws In W3C`() {
    let grammar = Grammar(Rule("start") {
      Repeat(...0) {
        "a"
      }
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .w3cEbnf)
    }
  }

  @Test
  func `Repeat Of Zero Through Zero Throws In W3C`() {
    let grammar = Grammar(Rule("start") {
      Repeat(0...0) {
        "a"
      }
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .w3cEbnf)
    }
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

  @Test
  func `Repeat With Partial Range Up To Zero Crashes`() async {
    await #expect(processExitsWith: .failure) {
      Repeat(..<0) { "a" }
    }
  }

  @Test
  func `Repeat With Partial Range Up To Negative One Crashes`() async {
    await #expect(processExitsWith: .failure) {
      Repeat(..<(-1)) { "a" }
    }
  }

  @Test
  func `Repeat With Partial Range Through Negative One Crashes`() async {
    await #expect(processExitsWith: .failure) {
      Repeat(...(-1)) { "a" }
    }
  }

  @Test
  func `Repeat With Closed Range Min Greater Than Max Crashes`() async {
    await #expect(processExitsWith: .failure) {
      Repeat(0...(-1)) { "a" }
    }
  }

  @Test
  func `Repeat With Exactly Negative Count Crashes`() async {
    await #expect(processExitsWith: .failure) {
      Repeat(exactly: -1) { "a" }
    }
  }

  @Test
  func `Repeat With Partial Range Up To Zero Crashes With Builder`() async {
    await #expect(processExitsWith: .failure) {
      Repeat(..<0) { "a" }
    }
  }

  @Test
  func `Repeat With Partial Range Up To Negative One Crashes With Builder`() async {
    await #expect(processExitsWith: .failure) {
      Repeat(..<(-1)) { "a" }
    }
  }

  @Test
  func `Repeat With Partial Range Through Negative One Crashes With Builder`() async {
    await #expect(processExitsWith: .failure) {
      Repeat(...(-1)) { "a" }
    }
  }

  @Test
  func `Repeat With Closed Range Min Greater Than Max Crashes With Builder`() async {
    await #expect(processExitsWith: .failure) {
      Repeat(0...(-1)) { "a" }
    }
  }

  @Test
  func `Repeat With Exactly Negative Count Crashes With Builder`() async {
    await #expect(processExitsWith: .failure) {
      Repeat(exactly: -1) { "a" }
    }
  }
}
