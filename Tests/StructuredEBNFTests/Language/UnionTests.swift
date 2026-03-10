import CustomDump
import Testing
import StructuredEBNF

@Suite
struct `Union tests` {
  @Test
  func `Union Combines Duplicate Productions With Choice`() {
    let language = Union {
      Grammar {
        Production("expression") { "first" }
        Production("term") { "value" }
      }
      Grammar {
        Production("expression") { "second" }
        Production("factor") { Ref("term") }
      }
    }

    expectNoDifference(
      language.language.grammar,
      Grammar {
        Production("g0__expression") { "first" }
        Production("g0__term") { "value" }
        Production("g1__expression") { "second" }
        Production("g1__factor") { Ref("g1__term") }
        Production("l0__start", Expression.choice([
          .ref("g0__expression"),
          .ref("g1__expression")
        ]))
      }
    )
  }

  @Test
  func `Union Builder Supports Conditional Branches`() {
    let usePrimary = true
    let language = Union {
      if usePrimary {
        Grammar {
          Production("expression") { "value" }
        }
      } else {
        Grammar {
          Production("term") { "other" }
        }
      }
    }

    expectNoDifference(
      language.language.grammar,
      Grammar {
        Production("g0__expression") { "value" }
        Production("l0__start") { Ref("g0__expression") }
      }
    )
  }
}
