import CustomDump
import StructuredCFG
import Testing
import XGrammar

@Suite
struct `GBNF Compilation Snapshot tests` {
  @Test(arguments: RepresentativeSnapshotLanguageSuite.cases)
  func `Representative GBNF Snapshots Compile`(
    snapshotCase: RepresentativeSnapshotLanguageCase
  ) async throws {
    let grammar = try XGrammar.Grammar(language: snapshotCase.language)
    let compiledGrammar = await grammar.compiled(for: Self.snapshotTokenizer)

    expectNoDifference(compiledGrammar.memorySize > 0, true)
  }

  private static let snapshotTokenizer = try! TokenizerInfo(encodedVocab: Self.snapshotVocabulary)

  private static let snapshotVocabulary =
    ["\t", "\n", "\r"] + (32...126).map { String(UnicodeScalar($0)!) }
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
