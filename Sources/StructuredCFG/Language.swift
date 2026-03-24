// MARK: - Language

/// A composable language graph that can be resolved into a concrete grammar.
///
/// ``Language`` lets you combine grammars with CFG operations like union, concatenation,
/// Kleene star, reversal, and homomorphism before resolving the result into a
/// ``Grammar``.
///
/// ```swift
/// let digits = Grammar(Rule("digits") {
///   OneOrMore {
///     CharacterGroup.digit
///   }
/// })
///
/// let identifier = Grammar(Rule("identifier") {
///   OneOrMore {
///     CharacterGroup.word
///   }
/// })
///
/// let language = Language {
///   Union {
///     digits
///     identifier
///   }
/// }
///
/// let resolved = language.grammar()
/// ```
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

  /// Creates an empty language.
  public init() {
    self.operation = .empty
  }

  /// Creates a language from a result-builder closure.
  ///
  /// - Parameter content: A builder that produces a ``Language`` composition.
  public init(@LanguageBuilder _ content: () -> Language) {
    self = content()
  }
}

// MARK: - Name Resolution

extension Language {
  /// Describes the language operation currently being resolved into a grammar.
  public enum GrammarOperation: Hashable, Sendable {
    /// Resolving a union of languages.
    case union
    /// Resolving a concatenation of languages.
    case concatenate
    /// Resolving a Kleene-star operation.
    case kleeneStar
    /// Resolving a reversal operation.
    case reverse
    /// Resolving a plain grammar leaf.
    case grammar
  }

  /// Context passed to name resolvers while synthesizing symbols.
  public struct GrammarNameResolutionContext: Sendable {
    /// The zero-based index of the grammar currently being resolved.
    public let grammarIndex: Int

    /// The current ``GrammarOperation``.
    public let currentOperation: GrammarOperation

    /// Symbols already present in the resolved grammar.
    public let existingSymbols: Set<Symbol>

    /// The ``Grammar`` values participating in the current resolution pass.
    public let grammars: [Grammar]
  }

  /// A symbol paired with the grammar it came from during resolution.
  public struct ResolvableGrammarSymbol: Sendable {
    /// The candidate ``Symbol``.
    public let symbol: Symbol

    /// The ``Grammar`` that owns the symbol.
    public let grammar: Grammar
  }
}

// MARK: - GrammarNameResolver

extension Language {
  /// Resolves symbol collisions while composing multiple grammars into one grammar.
  public protocol GrammarSymbolResolver: Sendable {
    /// Resolves a conflict between two symbols.
    ///
    /// - Parameters:
    ///   - new: The new ``ResolvableGrammarSymbol`` that conflicts with an existing one.
    ///   - existing: The existing `ResolvableGrammarSymbol`.
    ///   - context: The ``GrammarNameResolutionContext`` for the current operation.
    /// - Returns: A replacement ``Symbol`` for `new`.
    func resolveSymbolConflict(
      for new: ResolvableGrammarSymbol,
      against existing: ResolvableGrammarSymbol,
      context: GrammarNameResolutionContext
    ) -> Symbol

    /// Creates a synthesized entry symbol for a composed language.
    ///
    /// - Parameters:
    ///   - grammars: The ``Grammar`` values being resolved.
    ///   - context: The ``GrammarNameResolutionContext`` for the current operation.
    /// - Returns: A new non-conflicting ``Symbol``.
    func createNewSymbol(
      grammars: [Grammar],
      context: GrammarNameResolutionContext
    ) -> Symbol
  }

  /// The default symbol resolver used when composing languages into a grammar.
  public struct DefaultGrammarSymbolResolver: GrammarSymbolResolver {
    /// Creates the default resolver.
    public init() {}

    public func resolveSymbolConflict(
      for new: ResolvableGrammarSymbol,
      against existing: ResolvableGrammarSymbol,
      context: GrammarNameResolutionContext
    ) -> Symbol {
      Symbol(rawValue: "g\(self.letterNamespace(for: context.grammarIndex))\(new.symbol.rawValue)")
    }

    public func createNewSymbol(
      grammars: [Grammar],
      context: GrammarNameResolutionContext
    ) -> Symbol {
      Symbol(rawValue: "l\(self.letterNamespace(for: context.grammarIndex))start")
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

extension Language.GrammarSymbolResolver where Self == Language.DefaultGrammarSymbolResolver {
  /// The default name resolver.
  public static var `default`: Self { Self() }
}

// MARK: - Initializers

extension Language {
  /// Wraps a concrete grammar as a language leaf.
  ///
  /// - Parameter grammar: The ``Grammar`` to wrap.
  public init(_ grammar: Grammar) {
    self.operation = .grammar(grammar)
  }

  private init(operation: Operation) {
    self.operation = operation
  }
}

// MARK: - Operations

extension Language {
  /// Concatenates multiple languages into a single language.
  ///
  /// ```swift
  /// let language = Language.concatenate(
  ///   Grammar(Rule("digits") { OneOrMore { CharacterGroup.digit } }),
  ///   Grammar(Rule("equals") { "=" })
  /// )
  /// ```
  /// - Parameter languages: The ``LanguageComponent`` values to concatenate.
  /// - Returns: A ``Language`` that matches each input language in order.
  public static func concatenate(_ languages: [any LanguageComponent]) -> Self {
    Self(operation: .concatenate(languages.map { $0.language }))
  }

  /// Concatenates multiple languages into a single language.
  ///
  /// - Parameter languages: The ``LanguageComponent`` values to concatenate.
  /// - Returns: A ``Language`` that matches each input language in order.
  public static func concatenate(_ languages: any LanguageComponent...) -> Self {
    Self.concatenate(languages)
  }

  /// Unions multiple languages into a single language.
  ///
  /// - Parameter languages: The ``LanguageComponent`` values to union.
  /// - Returns: A ``Language`` that matches any of the input languages.
  public static func union(_ languages: [any LanguageComponent]) -> Self {
    Self(operation: .union(languages.map { $0.language }))
  }

  /// Unions multiple languages into a single language.
  ///
  /// - Parameter languages: The ``LanguageComponent`` values to union.
  /// - Returns: A ``Language`` that matches any of the input languages.
  public static func union(_ languages: any LanguageComponent...) -> Self {
    Self.union(languages)
  }

  /// Applies the Kleene-star operation to a language.
  ///
  /// - Parameter language: The ``LanguageComponent`` to repeat.
  /// - Returns: A ``Language`` that matches zero or more repetitions of `language`.
  public static func kleeneStar(_ language: some LanguageComponent) -> Self {
    Self(operation: .kleeneStar(language.language))
  }

  /// Reverses every terminal in a language.
  ///
  /// - Parameter language: The ``LanguageComponent`` to reverse.
  /// - Returns: A ``Language`` whose resolved grammar matches reversed terminal sequences.
  public static func reverse(_ language: some LanguageComponent) -> Self {
    Self(operation: .reverse(language.language))
  }
}

// MARK: - Mutation

extension Language {
  /// Replaces this language with the concatenation of itself and another language.
  ///
  /// - Parameter other: The ``LanguageComponent`` to append.
  public mutating func concatenate(_ other: some LanguageComponent) {
    self = self.concatenated(other)
  }

  /// Returns a language formed by concatenating this language with another language.
  ///
  /// - Parameter other: The ``LanguageComponent`` to append.
  /// - Returns: The concatenated ``Language``.
  public func concatenated(_ other: some LanguageComponent) -> Self {
    Self.concatenate([self, other.language])
  }

  /// Replaces this language with the union of itself and another language.
  ///
  /// - Parameter other: The ``LanguageComponent`` to union with this language.
  public mutating func formUnion(_ other: some LanguageComponent) {
    self = self.unioned(other)
  }

  /// Returns a language formed by unioning this language with another language.
  ///
  /// - Parameter other: The ``LanguageComponent`` to union with this language.
  /// - Returns: The unioned ``Language``.
  public func unioned(_ other: some LanguageComponent) -> Self {
    Self.union([self, other.language])
  }

  /// Replaces this language with its Kleene-star form.
  public mutating func formKleeneStar() {
    self = self.kleeneStarred()
  }

  /// Returns the Kleene-star form of this language.
  ///
  /// - Returns: The Kleene-starred ``Language``.
  public func kleeneStarred() -> Self {
    Self.kleeneStar(self)
  }

  /// Replaces this language with its reversed form.
  public mutating func reverse() {
    self = self.reversed()
  }

  /// Returns the reversed form of this language.
  ///
  /// - Returns: The reversed ``Language``.
  public func reversed() -> Self {
    Self.reverse(self)
  }

  /// Replaces every matching terminal in this language.
  ///
  /// ```swift
  /// var language = Language(Grammar(Rule("boolean") {
  ///   Choice {
  ///     "true"
  ///     "false"
  ///   }
  /// }))
  ///
  /// language.homomorph("true", to: "1")
  /// ```
  /// - Parameters:
  ///   - terminal: The ``Terminal`` to replace.
  ///   - replacement: The replacement `Terminal`.
  public mutating func homomorph(_ terminal: Terminal, to replacement: Terminal) {
    self = self.homomorphed(terminal, to: replacement)
  }

  /// Returns a copy of this language with every matching terminal replaced.
  ///
  /// - Parameters:
  ///   - terminal: The ``Terminal`` to replace.
  ///   - replacement: The replacement `Terminal`.
  /// - Returns: A transformed ``Language``.
  public func homomorphed(_ terminal: Terminal, to replacement: Terminal) -> Self {
    self.grammar().homomorphed(terminal, to: replacement).language
  }

  /// Applies a terminal transform across the resolved grammar of this language.
  ///
  /// - Parameter transform: A transform applied to each ``Terminal``.
  public mutating func homomorphMap(_ transform: (Terminal) -> Terminal?) {
    self = self.homomorphMapped(transform)
  }

  /// Returns a copy of this language after applying a terminal transform.
  ///
  /// - Parameter transform: A transform applied to each ``Terminal``.
  /// - Returns: A transformed ``Language``.
  public func homomorphMapped(_ transform: (Terminal) -> Terminal?) -> Self {
    self.grammar().homomorphMapped(transform).language
  }
}

// MARK: - Grammar

extension Language {
  /// Resolves the composed language into a concrete grammar.
  ///
  /// ```swift
  /// let resolved = Language {
  ///   Union {
  ///     Grammar(Rule("digits") { OneOrMore { CharacterGroup.digit } })
  ///     Grammar(Rule("identifier") { OneOrMore { CharacterGroup.word } })
  ///   }
  /// }
  /// .grammar(startingSymbol: .root)
  /// ```
  /// - Parameters:
  ///   - startingSymbol: The entry ``Symbol`` to expose from the resolved grammar.
  ///   - symbolResolver: The ``GrammarSymbolResolver`` used while merging grammars.
  /// - Returns: A concrete ``Grammar`` equivalent to this language.
  public func grammar(
    startingSymbol: Symbol = .root,
    symbolResolver: some GrammarSymbolResolver = .default
  ) -> Grammar {
    var resolver = Resolver(symbolResolver: symbolResolver)
    let resolved = resolver.resolve(self, operation: .grammar)
    guard let entrySymbol = resolved.entrySymbol else { return resolved.grammar }
    guard entrySymbol != startingSymbol else { return resolved.grammar }
    return Grammar(
      startingSymbol: startingSymbol,
      resolved.grammar.rules + [Rule(startingSymbol) { Ref(entrySymbol) }]
    )
  }

  /// Formats the resolved grammar using the supplied formatter.
  ///
  /// - Parameter formatter: The ``RuleFormatter`` used to serialize the resolved grammar.
  /// - Returns: The formatted representation of the resolved grammar.
  public func formatted(with formatter: some Grammar.RuleFormatter) throws -> String {
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
    var symbolResolver: any GrammarSymbolResolver
    var nextLanguageNamespace = 0
    var grammars: [Grammar] = []

    init(symbolResolver: some GrammarSymbolResolver) {
      self.symbolResolver = symbolResolver
    }

    mutating func resolve(_ language: Language, operation: GrammarOperation) -> ResolvedLanguage {
      switch language.operation {
      case .empty:
        return self.resolveEmptyOperation()
      case .grammar(let grammar):
        return self.resolveGrammarOperation(grammar)
      case .concatenate(let languages):
        return self.resolveMultipleLanguages(languages, operation: .concatenate) {
          entrySymbol,
          entrySymbols in
          Rule(entrySymbol) {
            for symbol in entrySymbols {
              Ref(symbol)
            }
          }
        }
      case .union(let languages):
        return self.resolveMultipleLanguages(languages, operation: .union) {
          entrySymbol,
          entrySymbols in
          if entrySymbols.count == 1 {
            Rule(entrySymbol) { Ref(entrySymbols[0]) }
          } else {
            Rule(entrySymbol, Expression.choice(entrySymbols.map { .ref(Ref($0)) }))
          }
        }
      case .kleeneStar(let language):
        return self.resolveKleeneStarOperation(language)
      case .reverse(let language):
        return self.resolveReverseOperation(language)
      }
    }

    private func resolveEmptyOperation() -> ResolvedLanguage {
      ResolvedLanguage(grammar: Grammar(), entrySymbol: nil, synthesizedEntry: false)
    }

    private func resolveGrammarOperation(_ grammar: Grammar) -> ResolvedLanguage {
      ResolvedLanguage(
        grammar: grammar,
        entrySymbol: grammar.rules.first?.symbol,
        synthesizedEntry: false
      )
    }

    private mutating func resolveMultipleLanguages(
      _ languages: [Language],
      operation: GrammarOperation,
      ruleBuilder: (Symbol, [Symbol]) -> Rule
    ) -> ResolvedLanguage {
      let resolved = languages.map { self.resolve($0, operation: operation) }
      let entrySymbols = resolved.compactMap(\.entrySymbol)
      guard !entrySymbols.isEmpty else {
        return ResolvedLanguage(grammar: Grammar(), entrySymbol: nil, synthesizedEntry: false)
      }
      var iterator = resolved.makeIterator()
      guard let first = iterator.next() else {
        return ResolvedLanguage(grammar: Grammar(), entrySymbol: nil, synthesizedEntry: false)
      }
      var grammar = first.grammar
      self.grammars = [grammar]
      var index = 1
      while let language = iterator.next() {
        grammar = self.mergeWithConflictResolution(
          grammar,
          language.grammar,
          index: index,
          operation: operation
        )
        self.grammars.append(language.grammar)
        index += 1
      }
      let entrySymbol = self.createNewSymbol()
      grammar.append(ruleBuilder(entrySymbol, entrySymbols))
      return ResolvedLanguage(grammar: grammar, entrySymbol: entrySymbol, synthesizedEntry: true)
    }

    private mutating func resolveKleeneStarOperation(_ language: Language) -> ResolvedLanguage {
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
    }

    private mutating func resolveReverseOperation(_ language: Language) -> ResolvedLanguage {
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

    private mutating func createNewSymbol() -> Symbol {
      let context = GrammarNameResolutionContext(
        grammarIndex: self.nextLanguageNamespace,
        currentOperation: .grammar,
        existingSymbols: Set(self.grammars.flatMap { $0.rules.map(\.symbol) }),
        grammars: self.grammars
      )
      let symbol = self.symbolResolver.createNewSymbol(grammars: self.grammars, context: context)
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
            let resolvedSymbol = self.symbolResolver.resolveSymbolConflict(
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
