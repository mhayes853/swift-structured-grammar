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

  public func grammar(startingSymbol: Symbol = .root) -> Grammar {
    var resolver = Resolver()
    let resolved = resolver.resolve(self)
    guard
      resolved.synthesizedEntry,
      let entrySymbol = resolved.entrySymbol,
      entrySymbol != startingSymbol
    else {
      return resolved.grammar
    }

    return Grammar(
      startingSymbol: startingSymbol,
      resolved.grammar.productions + [Production(startingSymbol) { Ref(entrySymbol) }]
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
    let entrySymbol: Symbol?
    let synthesizedEntry: Bool
  }

  private struct Resolver {
    var nextLanguageNamespace = 0

    mutating func resolve(_ language: Language) -> ResolvedLanguage {
      switch language.operation {
      case .empty:
        return ResolvedLanguage(grammar: Grammar(), entrySymbol: nil, synthesizedEntry: false)

      case let .grammar(grammar):
        return ResolvedLanguage(
          grammar: grammar,
          entrySymbol: grammar.productions.first?.symbol,
          synthesizedEntry: false
        )

      case let .concatenate(languages):
        let resolved = languages.map { self.resolve($0) }
        let entrySymbols = resolved.compactMap(\.entrySymbol)
        guard !entrySymbols.isEmpty else {
          return ResolvedLanguage(grammar: Grammar(), entrySymbol: nil, synthesizedEntry: false)
        }
        var iterator = resolved.makeIterator()
        var grammar = iterator.next()!.grammar
        while let language = iterator.next() {
          grammar.merge(language.grammar)
        }
        let entrySymbol = self.nextLanguageSymbol()
        grammar.append(Production(entrySymbol) {
          for symbol in entrySymbols {
            Ref(symbol)
          }
        })
        return ResolvedLanguage(grammar: grammar, entrySymbol: entrySymbol, synthesizedEntry: true)

      case let .union(languages):
        let resolved = languages.map { self.resolve($0) }
        let entrySymbols = resolved.compactMap(\.entrySymbol)
        guard !entrySymbols.isEmpty else {
          return ResolvedLanguage(grammar: Grammar(), entrySymbol: nil, synthesizedEntry: false)
        }
        var iterator = resolved.makeIterator()
        var grammar = iterator.next()!.grammar
        while let language = iterator.next() {
          grammar.merge(language.grammar)
        }
        let entrySymbol = self.nextLanguageSymbol()
        if entrySymbols.count == 1 {
          grammar.append(Production(entrySymbol) { Ref(entrySymbols[0]) })
        } else {
          grammar.append(Production(entrySymbol, Expression.choice(entrySymbols.map(Expression.ref))))
        }
        return ResolvedLanguage(grammar: grammar, entrySymbol: entrySymbol, synthesizedEntry: true)

      case let .kleeneStar(language):
        let resolved = self.resolve(language)
        guard let entrySymbol = resolved.entrySymbol else {
          return ResolvedLanguage(grammar: Grammar(), entrySymbol: nil, synthesizedEntry: false)
        }
        var grammar = resolved.grammar
        let synthesizedSymbol = self.nextLanguageSymbol()
        grammar.append(Production(synthesizedSymbol) {
          ZeroOrMore {
            Ref(entrySymbol)
          }
        })
        return ResolvedLanguage(
          grammar: grammar,
          entrySymbol: synthesizedSymbol,
          synthesizedEntry: true
        )

      case let .reverse(language):
        let resolved = self.resolve(language)
        guard let entrySymbol = resolved.entrySymbol else {
          return ResolvedLanguage(grammar: Grammar(), entrySymbol: nil, synthesizedEntry: false)
        }
        let grammar = self.reversed(grammar: resolved.grammar, startingSymbol: entrySymbol)
        return ResolvedLanguage(
          grammar: grammar,
          entrySymbol: entrySymbol,
          synthesizedEntry: true
        )
      }
    }

    mutating func nextLanguageSymbol() -> Symbol {
      let namespace = self.nextLanguageNamespace
      self.nextLanguageNamespace += 1
      return Symbol(rawValue: "l\(namespace)__start")!
    }

    private func reversed(grammar: Grammar, startingSymbol: Symbol) -> Grammar {
      let reachableSymbols = self.reachableSymbols(in: grammar, startingSymbol: startingSymbol)
      let productions = grammar.productions.compactMap { (production: Production) -> Production? in
        guard reachableSymbols.contains(production.symbol) else { return nil }
        return Production(production.symbol, self.reversed(expression: production.expression))
      }
      return Grammar(startingSymbol: startingSymbol, productions)
    }

    private func reachableSymbols(in grammar: Grammar, startingSymbol: Symbol) -> Set<Symbol> {
      var visited = Set<Symbol>()
      var stack = [startingSymbol]

      while let symbol = stack.popLast() {
        guard visited.insert(symbol).inserted else { continue }
        guard let production = grammar[symbol] else { continue }
        stack.append(contentsOf: self.referencedSymbols(in: production.expression))
      }

      return visited
    }

    private func referencedSymbols(in expression: Expression) -> [Symbol] {
      switch expression {
      case .empty:
        []
      case let .concat(expressions), let .choice(expressions):
        expressions.flatMap { self.referencedSymbols(in: $0) }
      case let .optional(expression), let .zeroOrMore(expression), let .group(expression):
        self.referencedSymbols(in: expression)
      case let .ref(symbol):
        [symbol]
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
      case let .ref(symbol):
        .ref(symbol)
      case let .special(special):
        .special(special)
      case let .terminal(terminal):
        .terminal(terminal)
      }
    }

  }
}
