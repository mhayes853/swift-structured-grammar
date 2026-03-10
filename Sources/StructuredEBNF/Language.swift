public struct Language: Hashable, Sendable, ConvertibleToLanguage {
  private indirect enum Operation: Hashable, Sendable {
    case empty
    case grammar(Grammar)
  }

  private let operation: Operation

  public var language: Language {
    self
  }

  public init() {
    self.operation = .empty
  }

  public init(@LanguageBuilder _ content: () -> Language) {
    self = content()
  }

  public var grammar: Grammar {
    switch self.operation {
    case .empty:
      Grammar()
    case let .grammar(grammar):
      grammar
    }
  }

  public func format() -> String {
    self.grammar.formatted()
  }

  init(grammar: Grammar) {
    self.operation = .grammar(grammar)
  }
}
