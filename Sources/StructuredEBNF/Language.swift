public struct Language: Hashable, Sendable, ConvertibleToLanguage {
  private indirect enum Operation: Hashable, Sendable {
    case empty
    case grammar(Grammar)
    case concatenate([Language])
    case union([Language])
    case kleeneStar(Language)
    case reverse(Language)
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

  public static func kleeneStar(_ language: some ConvertibleToLanguage) -> Self {
    Self(operation: .kleeneStar(language.language))
  }

  public static func reverse(_ language: some ConvertibleToLanguage) -> Self {
    Self(operation: .reverse(language.language))
  }

  public mutating func concatenate(_ other: some ConvertibleToLanguage) {
    self = self.concatenated(other)
  }

  public func concatenated(_ other: some ConvertibleToLanguage) -> Self {
    Self.concatenate([self, other.language])
  }

  public mutating func formUnion(_ other: some ConvertibleToLanguage) {
    self = self.unioned(other)
  }

  public func unioned(_ other: some ConvertibleToLanguage) -> Self {
    Self.union([self, other.language])
  }

  public mutating func formKleeneStar() {
    self = self.kleeneStarred()
  }

  public func kleeneStarred() -> Self {
    Self.kleeneStar(self)
  }

  public mutating func reverse() {
    self = self.reversed()
  }

  public func reversed() -> Self {
    Self.reverse(self)
  }

  public mutating func homomorph(_ terminal: Terminal, to replacement: Terminal) {
    self = self.homomorphed(terminal, to: replacement)
  }

  public func homomorphed(_ terminal: Terminal, to replacement: Terminal) -> Self {
    self.grammar().homomorphed(terminal, to: replacement).language
  }

  public mutating func homomorphMap(_ transform: (Terminal) -> Terminal?) {
    self = self.homomorphMapped(transform)
  }

  public func homomorphMapped(_ transform: (Terminal) -> Terminal?) -> Self {
    self.grammar().homomorphMapped(transform).language
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

    return Grammar(
      startingIdentifier: startingIdentifier,
      resolved.grammar.productions + [Production(startingIdentifier) { Ref(entryIdentifier) }]
    )
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
        let entryIdentifiers = resolved.compactMap(\.entryIdentifier)
        guard !entryIdentifiers.isEmpty else {
          return ResolvedLanguage(grammar: Grammar(), entryIdentifier: nil, synthesizedEntry: false)
        }
        var iterator = resolved.makeIterator()
        var grammar = iterator.next()!.grammar
        while let language = iterator.next() {
          grammar.merge(language.grammar)
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
        let entryIdentifiers = resolved.compactMap(\.entryIdentifier)
        guard !entryIdentifiers.isEmpty else {
          return ResolvedLanguage(grammar: Grammar(), entryIdentifier: nil, synthesizedEntry: false)
        }
        var iterator = resolved.makeIterator()
        var grammar = iterator.next()!.grammar
        while let language = iterator.next() {
          grammar.merge(language.grammar)
        }
        let entryIdentifier = self.nextLanguageIdentifier()
        if entryIdentifiers.count == 1 {
          grammar.append(Production(entryIdentifier) { Ref(entryIdentifiers[0]) })
        } else {
          grammar.append(Production(entryIdentifier, Expression.choice(entryIdentifiers.map(Expression.ref))))
        }
        return ResolvedLanguage(grammar: grammar, entryIdentifier: entryIdentifier, synthesizedEntry: true)

      case let .kleeneStar(language):
        let resolved = self.resolve(language)
        guard let entryIdentifier = resolved.entryIdentifier else {
          return ResolvedLanguage(grammar: Grammar(), entryIdentifier: nil, synthesizedEntry: false)
        }
        var grammar = resolved.grammar
        let synthesizedIdentifier = self.nextLanguageIdentifier()
        grammar.append(Production(synthesizedIdentifier) {
          ZeroOrMore {
            Ref(entryIdentifier)
          }
        })
        return ResolvedLanguage(
          grammar: grammar,
          entryIdentifier: synthesizedIdentifier,
          synthesizedEntry: true
        )

      case let .reverse(language):
        let resolved = self.resolve(language)
        guard let entryIdentifier = resolved.entryIdentifier else {
          return ResolvedLanguage(grammar: Grammar(), entryIdentifier: nil, synthesizedEntry: false)
        }
        let grammar = self.reversed(grammar: resolved.grammar, startingIdentifier: entryIdentifier)
        return ResolvedLanguage(
          grammar: grammar,
          entryIdentifier: entryIdentifier,
          synthesizedEntry: true
        )
      }
    }

    mutating func nextLanguageIdentifier() -> Identifier {
      let namespace = self.nextLanguageNamespace
      self.nextLanguageNamespace += 1
      return Identifier(rawValue: "l\(namespace)__start")!
    }

    private func reversed(grammar: Grammar, startingIdentifier: Identifier) -> Grammar {
      let reachableIdentifiers = self.reachableIdentifiers(in: grammar, startingIdentifier: startingIdentifier)
      let productions = grammar.productions.compactMap { (production: Production) -> Production? in
        guard reachableIdentifiers.contains(production.identifier) else { return nil }
        return Production(production.identifier, self.reversed(expression: production.expression))
      }
      return Grammar(startingIdentifier: startingIdentifier, productions)
    }

    private func reachableIdentifiers(in grammar: Grammar, startingIdentifier: Identifier) -> Set<Identifier> {
      var visited = Set<Identifier>()
      var stack = [startingIdentifier]

      while let identifier = stack.popLast() {
        guard visited.insert(identifier).inserted else { continue }
        guard let production = grammar[identifier] else { continue }
        stack.append(contentsOf: self.referencedIdentifiers(in: production.expression))
      }

      return visited
    }

    private func referencedIdentifiers(in expression: Expression) -> [Identifier] {
      switch expression {
      case .empty:
        []
      case let .concat(expressions), let .choice(expressions):
        expressions.flatMap { self.referencedIdentifiers(in: $0) }
      case let .optional(expression), let .zeroOrMore(expression), let .group(expression):
        self.referencedIdentifiers(in: expression)
      case let .ref(identifier):
        [identifier]
      case .special, .terminal:
        []
      }
    }

    private func reversed(expression: Expression) -> Expression {
      switch expression {
      case .empty:
        .empty
      case let .concat(expressions):
        .concat(expressions.reversed().map { self.reversed(expression: $0) })
      case let .choice(expressions):
        .choice(expressions.map { self.reversed(expression: $0) })
      case let .optional(expression):
        .optional(self.reversed(expression: expression))
      case let .zeroOrMore(expression):
        .zeroOrMore(self.reversed(expression: expression))
      case let .group(expression):
        .group(self.reversed(expression: expression))
      case let .ref(identifier):
        .ref(identifier)
      case let .special(special):
        .special(special)
      case let .terminal(terminal):
        .terminal(terminal)
      }
    }

  }
}
