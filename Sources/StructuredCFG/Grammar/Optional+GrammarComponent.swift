extension Optional: GrammarComponent where Wrapped: GrammarComponent {
  public var grammar: Grammar {
    self.map { $0.grammar } ?? Grammar()
  }
}
