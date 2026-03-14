extension Optional: GrammarComponent where Wrapped: GrammarComponent {
  public var grammar: Grammar {
    guard let wrapped = self else { return Grammar() }
    return wrapped.grammar
  }
}
