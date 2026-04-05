import CustomDump
import StructuredCFG
import Testing

@Suite
struct `InlineComment tests` {
  @Test
  func `Stores Base Expression And Position`() {
    let inlineComment = InlineComment("note", position: .leading) {
      Ref("value")
    }

    expectNoDifference(inlineComment.text, "note")
    expectNoDifference(inlineComment.position, .leading)
    expectNoDifference(inlineComment.baseExpression, Expression.ref(Ref("value")))
    expectNoDifference(inlineComment.expression, .inlineComment(inlineComment))
  }

  @Test
  func `Expression Components Can Be Annotated With Comment Modifier`() {
    let expression = Ref("value")
      .comment("note", position: .trailing)
      .expression

    expectNoDifference(
      expression,
      Expression.inlineComment(InlineComment("note", position: .trailing, Ref("value")))
    )
  }

  @Test
  func `Comment Modifier Defaults Position To Right`() {
    let expression = Ref("value")
      .comment("note")
      .expression

    expectNoDifference(
      expression,
      Expression.inlineComment(InlineComment("note", Ref("value")))
    )
  }

  @Test
  func `W3C Formatter Places Right Inline Comment After Expression`() throws {
    let grammar = Grammar(Rule("start") {
      InlineComment("note", position: .trailing) {
        "value"
      }
    })

    expectNoDifference(
      try grammar.formatted(with: .w3cEbnf),
      #"start ::= "value" /* note */"#
    )
  }

  @Test
  func `W3C Formatter Omits Inline Comment When Comment Style Is None`() throws {
    let grammar = Grammar(Rule("start") {
      InlineComment("note", position: .leading) {
        "value"
      }
    })

    expectNoDifference(
      try grammar.formatted(with: .w3cEbnf(commentStyle: .none)),
      #"start ::= "value""#
    )
  }

  @Test
  func `W3C Formatter Rejects Inline Comment With Line Comment Style`() {
    let grammar = Grammar(Rule("start") {
      InlineComment("note", position: .trailing) {
        "value"
      }
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .w3cEbnf(commentStyle: .line))
    }
  }

  @Test
  func `ISO Formatter Places Left Inline Comment Before Expression`() throws {
    let grammar = Grammar(Rule("start") {
      InlineComment("note", position: .leading) {
        "value"
      }
    })

    expectNoDifference(
      try grammar.formatted(with: .isoIecEbnf),
      #"start = (* note *) "value";"#
    )
  }

  @Test
  func `BNF Formatter Places Right Inline Comment After Expression`() throws {
    let grammar = Grammar(Rule("start") {
      InlineComment("note", position: .trailing) {
        "value"
      }
    })

    expectNoDifference(
      try grammar.formatted(with: .bnf),
      #"<start> ::= "value" /* note */"#
    )
  }

  @Test
  func `BNF Formatter Rejects Inline Comment With Line Comment Style`() {
    let grammar = Grammar(Rule("start") {
      InlineComment("note", position: .trailing) {
        "value"
      }
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .bnf(commentStyle: .line))
    }
  }

  @Test
  func `GBNF Formatter Rejects Inline Comments`() {
    let grammar = Grammar(Rule("start") {
      InlineComment("note", position: .trailing) {
        "value"
      }
    })

    #expect(throws: UnsupportedExpressionError.self) {
      try grammar.formatted(with: .gbnf)
    }
  }

  @Test
  func `Reverse Preserves Inline Comment While Reversing Wrapped Expression`() throws {
    let grammar = Grammar(Rule("start") {
      InlineComment("note", position: .leading) {
        ConcatenateExpressions {
          "a"
          "b"
        }
      }
    })

    expectNoDifference(
      try grammar.reversed().formatted(with: .isoIecEbnf),
      #"start = (* note *) "b", "a";"#
    )
  }

  @Test
  func `Homomorph Preserves Inline Comment While Rewriting Wrapped Expression`() throws {
    let grammar = Grammar(Rule("start") {
      InlineComment("note", position: .trailing) {
        "a"
      }
    })

    expectNoDifference(
      try grammar.homomorphed("a", to: "b").formatted(with: .w3cEbnf),
      #"start ::= "b" /* note */"#
    )
  }
}
