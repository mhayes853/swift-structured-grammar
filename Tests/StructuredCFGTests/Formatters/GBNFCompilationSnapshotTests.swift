#if canImport(XGrammar)
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

    private static let snapshotTokenizer = XGrammarTestSupport.matcherTokenizer
  }
#endif
