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

  public var grammar: Grammar {
    var resolver = Resolver()
    return resolver.resolve(self).grammar
  }

  public func format() -> String {
    self.grammar.formatted()
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
  }

  private struct Resolver {
    var nextGrammarNamespace = 0
    var nextLanguageNamespace = 0

    mutating func resolve(_ language: Language) -> ResolvedLanguage {
      switch language.operation {
      case .empty:
        return ResolvedLanguage(grammar: Grammar(), entryIdentifier: nil)

      case let .grammar(grammar):
        let namespace = self.nextGrammarNamespace
        self.nextGrammarNamespace += 1
        return self.namespace(grammar: grammar, namespace: "g\(namespace)")

      case let .concatenate(languages):
        let resolved = languages.map { self.resolve($0) }
        var grammar = Grammar()
        for language in resolved {
          grammar.merge(language.grammar)
        }
        let entryIdentifiers = resolved.compactMap(\.entryIdentifier)
        guard !entryIdentifiers.isEmpty else {
          return ResolvedLanguage(grammar: grammar, entryIdentifier: nil)
        }
        let entryIdentifier = self.nextLanguageIdentifier()
        grammar.append(Production(entryIdentifier) {
          for identifier in entryIdentifiers {
            Ref(identifier)
          }
        })
        return ResolvedLanguage(grammar: grammar, entryIdentifier: entryIdentifier)

      case let .union(languages):
        let resolved = languages.map { self.resolve($0) }
        var grammar = Grammar()
        for language in resolved {
          grammar.merge(language.grammar)
        }
        let entryIdentifiers = resolved.compactMap(\.entryIdentifier)
        guard !entryIdentifiers.isEmpty else {
          return ResolvedLanguage(grammar: grammar, entryIdentifier: nil)
        }
        let entryIdentifier = self.nextLanguageIdentifier()
        if entryIdentifiers.count == 1 {
          grammar.append(Production(entryIdentifier) { Ref(entryIdentifiers[0]) })
        } else {
          grammar.append(Production(entryIdentifier, Expression.choice(entryIdentifiers.map(Expression.ref))))
        }
        return ResolvedLanguage(grammar: grammar, entryIdentifier: entryIdentifier)
      }
    }

    mutating func nextLanguageIdentifier() -> Identifier {
      let namespace = self.nextLanguageNamespace
      self.nextLanguageNamespace += 1
      return Identifier(rawValue: "l\(namespace)__start")!
    }

    private mutating func namespace(grammar: Grammar, namespace: String) -> ResolvedLanguage {
      let namespacedProductions = grammar.productions.map { production in
        let identifier = self.qualify(production.identifier, namespace: namespace)
        return Production(identifier, self.namespace(expression: production.expression, namespace: namespace))
      }
      let namespacedGrammar = Grammar(namespacedProductions)
      return ResolvedLanguage(
        grammar: namespacedGrammar,
        entryIdentifier: namespacedProductions.first?.identifier
      )
    }

    private func namespace(expression: Expression, namespace: String) -> Expression {
      switch expression {
      case .empty:
        .empty
      case let .concat(expressions):
        .concat(expressions.map { self.namespace(expression: $0, namespace: namespace) })
      case let .choice(expressions):
        .choice(expressions.map { self.namespace(expression: $0, namespace: namespace) })
      case let .optional(expression):
        .optional(self.namespace(expression: expression, namespace: namespace))
      case let .zeroOrMore(expression):
        .zeroOrMore(self.namespace(expression: expression, namespace: namespace))
      case let .group(expression):
        .group(self.namespace(expression: expression, namespace: namespace))
      case let .ref(identifier):
        .ref(self.qualify(identifier, namespace: namespace))
      case let .special(special):
        .special(special)
      case let .terminal(terminal):
        .terminal(terminal)
      }
    }

    private func qualify(_ identifier: Identifier, namespace: String) -> Identifier {
      Identifier(rawValue: "\(namespace)__\(identifier.rawValue)")!
    }
  }
}
