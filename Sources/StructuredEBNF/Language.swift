public struct Language: Hashable, Sendable, ConvertibleToLanguage {
  private indirect enum Operation: Hashable, Sendable {
    case empty
    case grammar(Grammar)
    case concatenate([Language])
    case union([Language])
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

  public static func concatenate(_ languages: [any ConvertibleToLanguage]) -> Self {
    Self(operation: .concatenate(languages.map { $0.language }))
  }

  public static func concatenate(_ languages: any ConvertibleToLanguage...) -> Self {
    Self.concatenate(languages)
  }

  public static func union(_ languages: [any ConvertibleToLanguage]) -> Self {
    Self(operation: .union(languages.map { $0.language }))
  }

  public static func union(_ languages: any ConvertibleToLanguage...) -> Self {
    Self.union(languages)
  }

  public func grammar(startingIdentifier: Identifier = .root) -> Grammar {
    var resolver = Resolver()
    let resolved = resolver.resolve(self)
    guard
      resolved.synthesizedEntry,
      let entryIdentifier = resolved.entryIdentifier,
      entryIdentifier != startingIdentifier
    else {
      return resolved.grammar
    }

    var grammar = resolved.grammar
    grammar.append(Production(startingIdentifier) { Ref(entryIdentifier) })
    return grammar
  }

  public func format() -> String {
    self.grammar().formatted()
  }

  init(grammar: Grammar) {
    self.operation = .grammar(grammar)
  }

  private init(operation: Operation) {
    self.operation = operation
  }

  private struct ResolvedLanguage {
    let grammar: Grammar
    let entryIdentifier: Identifier?
    let synthesizedEntry: Bool
  }

  private struct Resolver {
    var nextLanguageNamespace = 0

    mutating func resolve(_ language: Language) -> ResolvedLanguage {
      switch language.operation {
      case .empty:
        return ResolvedLanguage(grammar: Grammar(), entryIdentifier: nil, synthesizedEntry: false)

      case let .grammar(grammar):
        return ResolvedLanguage(
          grammar: grammar,
          entryIdentifier: grammar.productions.first?.identifier,
          synthesizedEntry: false
        )

      case let .concatenate(languages):
        let resolved = languages.map { self.resolve($0) }
        var grammar = Grammar()
        for language in resolved {
          grammar.merge(language.grammar)
        }
        let entryIdentifiers = resolved.compactMap(\.entryIdentifier)
        guard !entryIdentifiers.isEmpty else {
          return ResolvedLanguage(grammar: grammar, entryIdentifier: nil, synthesizedEntry: false)
        }
        let entryIdentifier = self.nextLanguageIdentifier()
        grammar.append(Production(entryIdentifier) {
          for identifier in entryIdentifiers {
            Ref(identifier)
          }
        })
        return ResolvedLanguage(grammar: grammar, entryIdentifier: entryIdentifier, synthesizedEntry: true)

      case let .union(languages):
        let resolved = languages.map { self.resolve($0) }
        var grammar = Grammar()
        for language in resolved {
          grammar.merge(language.grammar)
        }
        let entryIdentifiers = resolved.compactMap(\.entryIdentifier)
        guard !entryIdentifiers.isEmpty else {
          return ResolvedLanguage(grammar: grammar, entryIdentifier: nil, synthesizedEntry: false)
        }
        let entryIdentifier = self.nextLanguageIdentifier()
        if entryIdentifiers.count == 1 {
          grammar.append(Production(entryIdentifier) { Ref(entryIdentifiers[0]) })
        } else {
          grammar.append(Production(entryIdentifier, Expression.choice(entryIdentifiers.map(Expression.ref))))
        }
        return ResolvedLanguage(grammar: grammar, entryIdentifier: entryIdentifier, synthesizedEntry: true)
      }
    }

    mutating func nextLanguageIdentifier() -> Identifier {
      let namespace = self.nextLanguageNamespace
      self.nextLanguageNamespace += 1
      return Identifier(rawValue: "l\(namespace)__start")!
    }

  }
}
