import CustomDump
import StructuredCFG
import Testing

@Suite
struct `Representative Language Behavior tests` {
  @Test(arguments: Self.cases.map(\.name))
  func `Representative Languages Accept Expected Inputs`(behaviorCaseName: String) async throws {
    let behaviorCase = Self.behaviorCase(named: behaviorCaseName)
    for input in behaviorCase.accepts {
      let matches = try await XGrammarTestSupport.matches(input, language: behaviorCase.language)
      expectNoDifference(matches, true)
    }
  }

  @Test(arguments: Self.cases.map(\.name))
  func `Representative Languages Reject Unexpected Inputs`(behaviorCaseName: String) async throws {
    let behaviorCase = Self.behaviorCase(named: behaviorCaseName)
    for input in behaviorCase.rejects {
      let matches = try await XGrammarTestSupport.matches(input, language: behaviorCase.language)
      expectNoDifference(matches, false)
    }
  }

  struct BehaviorCase: Hashable, Sendable {
    let name: String
    let language: Language
    let accepts: [String]
    let rejects: [String]
  }

  private static let cases: [BehaviorCase] = [
    BehaviorCase(
      name: "arithmetic-grammar",
      language: Self.representativeLanguage(named: "arithmetic-grammar"),
      accepts: ["0", "1+2", "(1)", "2*1-0"],
      rejects: ["", "+1", "3", "1+"]
    ),
    BehaviorCase(
      name: "unioned-grammar",
      language: Self.representativeLanguage(named: "unioned-grammar"),
      accepts: ["pass", "letidentifier", "0", "1"],
      rejects: ["let", "identifier", "2", "other"]
    ),
    BehaviorCase(
      name: "helper-production-grammar",
      language: Self.representativeLanguage(named: "helper-production-grammar"),
      accepts: ["", "a", "abba"],
      rejects: ["c", "abc"]
    ),
    BehaviorCase(
      name: "concatenated-grammar",
      language: Self.representativeLanguage(named: "concatenated-grammar"),
      accepts: ["ab"],
      rejects: ["", "a", "b", "ba"]
    ),
    BehaviorCase(
      name: "reversed-grammar",
      language: Self.representativeLanguage(named: "reversed-grammar"),
      accepts: ["cba"],
      rejects: ["abc", "cb", "cab"]
    )
  ]

  private static func representativeLanguage(named name: String) -> Language {
    RepresentativeSnapshotLanguageSuite.cases.first(where: { $0.name == name })!.language
  }

  private static func behaviorCase(named name: String) -> BehaviorCase {
    Self.cases.first(where: { $0.name == name })!
  }
}
