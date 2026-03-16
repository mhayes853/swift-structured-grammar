// MARK: - Language

public struct Language: Hashable, Sendable, LanguageComponent {
  private indirect enum Operation: Hashable, Sendable {
    case empty
    case grammar(Grammar)
    case concatenate([Language])
    case union([Language])
    case kleeneStar(Language)
    case reverse(Language)
  }

  private let operation: Operation

  @LanguageBuilder
  public var language: Language {
    self
  }

  public init() {
    self.operation = .empty
  }

  public init(@LanguageBuilder _ content: () -> Language) {
    self = content()
  }
}

// MARK: - Name Resolution

extension Language {
  public enum GrammarOperation: Hashable, Sendable {
    case union
    case concatenate
    case kleeneStar
    case reverse
    case grammar
  }

  public struct GrammarNameResolutionContext: Sendable {
    public let grammarIndex: Int
    public let currentOperation: GrammarOperation
    public let existingSymbols: Set<Symbol>
    public let grammars: [Grammar]
  }

  public struct ResolvableGrammarSymbol: Sendable {
    public let symbol: Symbol
    public let grammar: Grammar
  }
}

// MARK: - GrammarNameResolver

extension Language {
  public protocol GrammarNameResolver: Sendable {
    func resolveSymbolConflict(
      for new: ResolvableGrammarSymbol,
      against existing: ResolvableGrammarSymbol,
      context: GrammarNameResolutionContext
    ) -> Symbol

    func createNewSymbol(
      grammars: [Grammar],
      context: GrammarNameResolutionContext
    ) -> Symbol
  }

  public struct DefaultGrammarNameResolver: GrammarNameResolver {
    public init() {}

    public func resolveSymbolConflict(
      for new: ResolvableGrammarSymbol,
      against existing: ResolvableGrammarSymbol,
      context: GrammarNameResolutionContext
    ) -> Symbol {
      Symbol(rawValue: "g\(self.letterNamespace(for: context.grammarIndex))\(new.symbol.rawValue)")!
    }

    public func createNewSymbol(
      grammars: [Grammar],
      context: GrammarNameResolutionContext
    ) -> Symbol {
      Symbol(rawValue: "l\(self.letterNamespace(for: context.grammarIndex))start")!
    }

    private func letterNamespace(for index: Int) -> String {
      precondition(index >= 0, "Grammar indices must be non-negative.")

      var quotient = index
      var namespace = ""

      repeat {
        let remainder = quotient % 26
        let scalar = UnicodeScalar(UInt8(ascii: "a") + UInt8(remainder))
        namespace.insert(Character(scalar), at: namespace.startIndex)
        quotient = (quotient / 26) - 1
      } while quotient >= 0

      return namespace
    }
  }
}

extension Language.GrammarNameResolver where Self == Language.DefaultGrammarNameResolver {
  public static var `default`: Self { Self() }
}

// MARK: - Initializers

extension Language {
  public init(_ grammar: Grammar) {
    self.operation = .grammar(grammar)
  }

  private init(operation: Operation) {
    self.operation = operation
  }
}

// MARK: - Operations

extension Language {
  public static func concatenate(_ languages: [any LanguageComponent]) -> Self {
    Self(operation: .concatenate(languages.map { $0.language }))
  }

  public static func concatenate(_ languages: any LanguageComponent...) -> Self {
    Self.concatenate(languages)
  }

  public static func union(_ languages: [any LanguageComponent]) -> Self {
    Self(operation: .union(languages.map { $0.language }))
  }

  public static func union(_ languages: any LanguageComponent...) -> Self {
    Self.union(languages)
  }

  public static func kleeneStar(_ language: some LanguageComponent) -> Self {
    Self(operation: .kleeneStar(language.language))
  }

  public static func reverse(_ language: some LanguageComponent) -> Self {
    Self(operation: .reverse(language.language))
  }
}

// MARK: - Mutation

extension Language {
  public mutating func concatenate(_ other: some LanguageComponent) {
    self = self.concatenated(other)
  }

  public func concatenated(_ other: some LanguageComponent) -> Self {
    Self.concatenate([self, other.language])
  }

  public mutating func formUnion(_ other: some LanguageComponent) {
    self = self.unioned(other)
  }

  public func unioned(_ other: some LanguageComponent) -> Self {
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
}

// MARK: - Grammar

extension Language {
  public func grammar(
    startingSymbol: Symbol = .root,
    nameResolver: some GrammarNameResolver = .default
  ) -> Grammar {
    var resolver = Resolver(nameResolver: nameResolver)
    let resolved = resolver.resolve(self, operation: .grammar)
    guard let entrySymbol = resolved.entrySymbol else { return resolved.grammar }
    guard entrySymbol != startingSymbol else { return resolved.grammar }
    return Grammar(
      startingSymbol: startingSymbol,
      resolved.grammar.rules + [Rule(startingSymbol) { Ref(entrySymbol) }]
    )
  }

  public func formatted(with formatter: some Grammar.Formatter) throws -> String {
    try self.grammar().formatted(with: formatter)
  }
}

// MARK: - Resolver

extension Language {
  private struct ResolvedLanguage {
    let grammar: Grammar
    let entrySymbol: Symbol?
    let synthesizedEntry: Bool
  }

  private struct Resolver {
    var nameResolver: any GrammarNameResolver
    var nextLanguageNamespace = 0
    var grammars: [Grammar] = []

    init(nameResolver: some GrammarNameResolver) {
      self.nameResolver = nameResolver
    }

    mutating func resolve(_ language: Language, operation: GrammarOperation) -> ResolvedLanguage {
      switch language.operation {
      case .empty:
        return ResolvedLanguage(grammar: Grammar(), entrySymbol: nil, synthesizedEntry: false)

      case .grammar(let grammar):
        return ResolvedLanguage(
          grammar: grammar,
          entrySymbol: grammar.rules.first?.symbol,
          synthesizedEntry: false
        )

      case .concatenate(let languages):
        let resolved = languages.map { self.resolve($0, operation: .concatenate) }
        let entrySymbols = resolved.compactMap(\.entrySymbol)
        guard !entrySymbols.isEmpty else {
          return ResolvedLanguage(grammar: Grammar(), entrySymbol: nil, synthesizedEntry: false)
        }
        var iterator = resolved.makeIterator()
        var grammar = iterator.next()!.grammar
        self.grammars = [grammar]
        var index = 1
        while let language = iterator.next() {
          grammar = self.mergeWithConflictResolution(
            grammar,
            language.grammar,
            index: index,
            operation: .concatenate
          )
          self.grammars.append(language.grammar)
          index += 1
        }
        let entrySymbol = self.createNewSymbol()
        grammar.append(
          Rule(entrySymbol) {
            for symbol in entrySymbols {
              Ref(symbol)
            }
          }
        )
        return ResolvedLanguage(grammar: grammar, entrySymbol: entrySymbol, synthesizedEntry: true)

      case .union(let languages):
        let resolved = languages.map { self.resolve($0, operation: .union) }
        let entrySymbols = resolved.compactMap(\.entrySymbol)
        guard !entrySymbols.isEmpty else {
          return ResolvedLanguage(grammar: Grammar(), entrySymbol: nil, synthesizedEntry: false)
        }
        var iterator = resolved.makeIterator()
        var grammar = iterator.next()!.grammar
        self.grammars = [grammar]
        var index = 1
        while let language = iterator.next() {
          grammar = self.mergeWithConflictResolution(
            grammar,
            language.grammar,
            index: index,
            operation: .union
          )
          self.grammars.append(language.grammar)
          index += 1
        }
        let entrySymbol = self.createNewSymbol()
        if entrySymbols.count == 1 {
          grammar.append(Rule(entrySymbol) { Ref(entrySymbols[0]) })
        } else {
          grammar.append(
            Rule(entrySymbol, Expression.choice(entrySymbols.map(Expression.ref)))
          )
        }
        return ResolvedLanguage(grammar: grammar, entrySymbol: entrySymbol, synthesizedEntry: true)

      case .kleeneStar(let language):
        let resolved = self.resolve(language, operation: .kleeneStar)
        guard let entrySymbol = resolved.entrySymbol else {
          return ResolvedLanguage(grammar: Grammar(), entrySymbol: nil, synthesizedEntry: false)
        }
        var grammar = resolved.grammar
        self.grammars = [grammar]
        let synthesizedSymbol = self.createNewSymbol()
        grammar.append(
          Rule(synthesizedSymbol) {
            ZeroOrMore {
              Ref(entrySymbol)
            }
          }
        )
        return ResolvedLanguage(
          grammar: grammar,
          entrySymbol: synthesizedSymbol,
          synthesizedEntry: true
        )

      case .reverse(let language):
        let resolved = self.resolve(language, operation: .reverse)
        guard let entrySymbol = resolved.entrySymbol else {
          return ResolvedLanguage(grammar: Grammar(), entrySymbol: nil, synthesizedEntry: false)
        }
        let grammar = resolved.grammar.reversed()
        return ResolvedLanguage(
          grammar: grammar,
          entrySymbol: entrySymbol,
          synthesizedEntry: true
        )
      }
    }

    private mutating func createNewSymbol() -> Symbol {
      let context = GrammarNameResolutionContext(
        grammarIndex: self.nextLanguageNamespace,
        currentOperation: .grammar,
        existingSymbols: Set(self.grammars.flatMap { $0.rules.map(\.symbol) }),
        grammars: self.grammars
      )
      let symbol = self.nameResolver.createNewSymbol(grammars: self.grammars, context: context)
      self.nextLanguageNamespace += 1
      return symbol
    }

    private mutating func mergeWithConflictResolution(
      _ base: Grammar,
      _ incoming: Grammar,
      index: Int,
      operation: GrammarOperation
    ) -> Grammar {
      var result = base
      let existingSymbols = Set(base.rules.map(\.symbol))
      var allGrammars = self.grammars
      allGrammars.append(incoming)
      let context = GrammarNameResolutionContext(
        grammarIndex: index,
        currentOperation: operation,
        existingSymbols: existingSymbols,
        grammars: allGrammars
      )

      for production in incoming.rules {
        if existingSymbols.contains(production.symbol) {
          if let existingRule = base.rules.first(where: {
            $0.symbol == production.symbol
          }) {
            let resolvedSymbol = self.nameResolver.resolveSymbolConflict(
              for: ResolvableGrammarSymbol(symbol: production.symbol, grammar: incoming),
              against: ResolvableGrammarSymbol(symbol: existingRule.symbol, grammar: base),
              context: context
            )
            result.append(Rule(resolvedSymbol, production.expression))
          }
        } else {
          result.append(production)
        }
      }

      return result
    }
  }
}
