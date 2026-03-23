import StructuredCFG
import XGrammar

enum XGrammarTestSupport {
  static let matcherVocabulary = ["\t", "\n", "\r"]
    + (32...126).map { String(UnicodeScalar($0)!) }
    + ["é"]

  static let matcherTokenizer = try! TokenizerInfo(encodedVocab: Self.matcherVocabulary)

  static let matcherTokenIDs = Dictionary(
    uniqueKeysWithValues: Self.matcherVocabulary.enumerated().map { ($1, Int32($0)) }
  )
}

extension XGrammar.Grammar {
  init(
    language: Language,
    startingSymbol: Symbol = .root,
    nameResolver: Language.GrammarNameResolver = .default
  ) throws {
    try self.init(
      grammar: language.grammar(startingSymbol: startingSymbol, nameResolver: nameResolver)
    )
  }

  init(grammar: StructuredCFG.Grammar) throws {
    self.init(ebnf: try grammar.formatted(with: .gbnf), rootRule: grammar.startingSymbol.rawValue)
  }
}

extension XGrammarTestSupport {
  static func matcher(for language: Language) async throws -> XGrammar.Grammar.Matcher {
    let grammar = try XGrammar.Grammar(language: language)
    return try await grammar.matcher(
      for: Self.matcherTokenizer,
      terminatesWithoutStopToken: true
    )
  }

  static func matches(_ input: String, language: Language) async throws -> Bool {
    let matcher = try await Self.matcher(for: language)

    for token in input.map(String.init) {
      guard let tokenID = Self.matcherTokenIDs[token] else {
        return false
      }
      guard matcher.accept(tokenID) else {
        return false
      }
    }

    return matcher.isTerminated
  }
}
