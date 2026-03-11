// MARK: - Grammar

public struct Grammar: Hashable, Sendable, ConvertibleToLanguage {
  public var startingSymbol: Symbol {
    didSet {
      self.updateStartingSymbol(from: oldValue)
    }
  }
  private var orderedSymbols: [Symbol]
  private var productionsBySymbol: [Symbol: Production]

  public var productions: Productions {
    Productions(
      orderedSymbols: self.orderedSymbols,
      productionsBySymbol: self.productionsBySymbol
    )
  }

  public var language: Language {
    Language(grammar: self)
  }

  public init() {
    self.init(Production(.root) { EmptyExpression() })
  }

  public init(_ production: Production) {
    self.init(startingSymbol: production.symbol, CollectionOfOne(production))
  }

  public init(startingSymbol: Symbol, _ productions: some Sequence<Production>) {
    self.startingSymbol = startingSymbol
    self.orderedSymbols = [startingSymbol]
    self.productionsBySymbol = [
      startingSymbol: Production(startingSymbol) { EmptyExpression() }
    ]
    for production in productions {
      self.append(production)
    }
  }

  public init(startingSymbol: Symbol, @GrammarBuilder _ content: () -> [Production]) {
    self.init(startingSymbol: startingSymbol, content())
  }

  private init(
    startingSymbol: Symbol,
    orderedSymbols: [Symbol],
    productionsBySymbol: [Symbol: Production]
  ) {
    self.startingSymbol = startingSymbol
    self.orderedSymbols = orderedSymbols
    self.productionsBySymbol = productionsBySymbol
  }

  public func production(for symbol: Symbol) -> Production? {
    self.productionsBySymbol[symbol]
  }

  public func containsProduction(for symbol: Symbol) -> Bool {
    self.productionsBySymbol[symbol] != nil
  }

  public subscript(_ symbol: Symbol) -> Production? {
    self.productionsBySymbol[symbol]
  }

  public subscript(index: Int) -> Production {
    self.productions[index]
  }

  public mutating func append(_ production: Production) {
    self.replaceProduction(for: production.symbol, with: production)
  }

  public mutating func append(contentsOf productions: some Sequence<Production>) {
    for production in productions {
      self.append(production)
    }
  }

  public func appending(_ production: Production) -> Self {
    var grammar = self
    grammar.append(production)
    return grammar
  }

  public func appending(contentsOf productions: some Sequence<Production>) -> Self {
    var grammar = self
    grammar.append(contentsOf: productions)
    return grammar
  }

  public mutating func removeProduction(for symbol: Symbol) {
    if symbol == self.startingSymbol {
      self.productionsBySymbol[symbol] = Production(symbol) { EmptyExpression() }
      return
    }
    self.orderedSymbols.removeAll { $0 == symbol }
    self.productionsBySymbol[symbol] = nil
  }

  public mutating func removeAll() {
    self.orderedSymbols = [self.startingSymbol]
    self.productionsBySymbol = [
      self.startingSymbol: Production(self.startingSymbol) { EmptyExpression() }
    ]
  }

  public mutating func removeAll(where shouldBeRemoved: (Production) -> Bool) {
    let removedSymbols = Set<Symbol>(
      self.orderedSymbols.compactMap { symbol in
        guard let production = self.productionsBySymbol[symbol] else { return nil }
        return shouldBeRemoved(production) ? symbol : nil
      }
    )

    self.orderedSymbols.removeAll { removedSymbols.contains($0) }
    self.productionsBySymbol = self.productionsBySymbol.filter { !removedSymbols.contains($0.key) }
    if removedSymbols.contains(self.startingSymbol) {
      self.productionsBySymbol[self.startingSymbol] = Production(self.startingSymbol) {
        EmptyExpression()
      }
      if !self.orderedSymbols.contains(self.startingSymbol) {
        self.orderedSymbols.insert(self.startingSymbol, at: 0)
      }
    }
  }

  public mutating func replaceProduction(
    for symbol: Symbol,
    with expression: some ConvertibleToExpression
  ) {
    self.replaceProduction(for: symbol, with: Production(symbol, expression))
  }

  public mutating func replaceProduction(
    for symbol: Symbol,
    with string: String
  ) {
    self.replaceProduction(for: symbol, with: Terminal(string))
  }

  public mutating func replaceProduction(
    for symbol: Symbol,
    @ExpressionBuilder _ expression: () -> Expression
  ) {
    self.replaceProduction(for: symbol, with: expression())
  }

  public func replacingProduction(
    for symbol: Symbol,
    with expression: some ConvertibleToExpression
  ) -> Self {
    var grammar = self
    grammar.replaceProduction(for: symbol, with: expression)
    return grammar
  }

  public func replacingProduction(
    for symbol: Symbol,
    with string: String
  ) -> Self {
    var grammar = self
    grammar.replaceProduction(for: symbol, with: string)
    return grammar
  }

  public func replacingProduction(
    for symbol: Symbol,
    @ExpressionBuilder _ expression: () -> Expression
  ) -> Self {
    var grammar = self
    grammar.replaceProduction(for: symbol, with: expression())
    return grammar
  }

  private mutating func replaceProduction(for symbol: Symbol, with production: Production) {
    if self.productionsBySymbol[symbol] == nil {
      self.appendSymbolIfNeeded(symbol)
    }
    self.productionsBySymbol[symbol] = production
  }

  public mutating func merge(_ grammar: Grammar) {
    for production in grammar.productions {
      self.replaceProduction(for: production.symbol, with: production)
    }
  }

  public func merging(_ grammar: Grammar) -> Self {
    var merged = self
    merged.merge(grammar)
    return merged
  }

  private mutating func appendSymbolIfNeeded(_ symbol: Symbol) {
    guard !self.orderedSymbols.contains(symbol) else { return }
    if symbol == self.startingSymbol {
      self.orderedSymbols.insert(symbol, at: 0)
    } else {
      self.orderedSymbols.append(symbol)
    }
  }

  private mutating func updateStartingSymbol(from oldValue: Symbol) {
    guard self.startingSymbol != oldValue else { return }
    if self.productionsBySymbol[self.startingSymbol] == nil {
      self.productionsBySymbol[self.startingSymbol] = Production(self.startingSymbol) {
        EmptyExpression()
      }
    }
    self.orderedSymbols.removeAll { $0 == self.startingSymbol }
    self.orderedSymbols.insert(self.startingSymbol, at: 0)
  }
}

// MARK: - Homomorphism

extension Grammar {
  public mutating func homomorphMap(_ transform: (Terminal) -> Terminal?) {
    self.productionsBySymbol = self.productionsBySymbol.mapValues { production in
      Production(production.symbol, self.homomorphed(expression: production.expression, transform: transform))
    }
  }

  public func homomorphMapped(_ transform: (Terminal) -> Terminal?) -> Self {
    var grammar = self
    grammar.homomorphMap(transform)
    return grammar
  }

  public mutating func homomorph(_ terminal: Terminal, to replacement: Terminal) {
    self.homomorphMap { candidate in
      candidate == terminal ? replacement : nil
    }
  }

  public func homomorphed(_ terminal: Terminal, to replacement: Terminal) -> Self {
    self.homomorphMapped { candidate in
      candidate == terminal ? replacement : nil
    }
  }

  private func homomorphed(expression: Expression, transform: (Terminal) -> Terminal?) -> Expression {
    switch expression {
    case .empty:
      .empty
    case let .concat(expressions):
      .concat(expressions.map { self.homomorphed(expression: $0, transform: transform) })
    case let .choice(expressions):
      .choice(expressions.map { self.homomorphed(expression: $0, transform: transform) })
    case let .optional(expression):
      .optional(self.homomorphed(expression: expression, transform: transform))
    case let .zeroOrMore(expression):
      .zeroOrMore(self.homomorphed(expression: expression, transform: transform))
    case let .group(expression):
      .group(self.homomorphed(expression: expression, transform: transform))
    case let .ref(symbol):
      .ref(symbol)
    case let .special(special):
      .special(special)
    case let .terminal(terminal):
      transform(terminal).map(Expression.terminal) ?? .terminal(terminal)
    }
  }
}

// MARK: - Formatting

extension Grammar {
  public func formatted() -> String {
    self.productions
      .map { production in
        let formattedExpression = self.format(expression: production.expression)
        if formattedExpression.isEmpty {
          return "\(production.symbol.rawValue) = ;"
        } else {
          return "\(production.symbol.rawValue) = \(formattedExpression) ;"
        }
      }
      .joined(separator: "\n")
  }

  private func format(expression: Expression) -> String {
    switch expression {
    case .empty:
      ""
    case let .concat(expressions):
      expressions
        .map { expression in
          if case .choice = expression {
            "(\(self.format(expression: expression)))"
          } else {
            self.format(expression: expression)
          }
        }
        .joined(separator: ", ")
    case let .choice(expressions):
      expressions.map { self.format(expression: $0) }.joined(separator: " | ")
    case let .optional(expression):
      "[\(self.format(expression: expression))]"
    case let .zeroOrMore(expression):
      "{\(self.format(expression: expression))}"
    case let .group(expression):
      "(\(self.format(expression: expression)))"
    case let .ref(symbol):
      symbol.rawValue
    case let .special(special):
      "? \(special.value) ?"
    case let .terminal(terminal):
      self.format(terminal: terminal)
    }
  }

  private func format(terminal: Terminal) -> String {
    let escaped = terminal.value.reduce(into: "") { result, character in
      switch character {
      case "\\":
        result += "\\\\"
      case #"""#:
        result += #"\""#
      default:
        result.append(character)
      }
    }

    return "\"" + escaped + "\""
  }
}

// MARK: - Productions

extension Grammar {
  public struct Productions: RandomAccessCollection, Sendable {
    public typealias Element = Production
    public typealias Index = Int

    private let orderedSymbols: [Symbol]
    private let productionsBySymbol: [Symbol: Production]

    init(orderedSymbols: [Symbol], productionsBySymbol: [Symbol: Production]) {
      self.orderedSymbols = orderedSymbols
      self.productionsBySymbol = productionsBySymbol
    }

    public var startIndex: Int {
      self.orderedSymbols.startIndex
    }

    public var endIndex: Int {
      self.orderedSymbols.endIndex
    }

    public subscript(position: Int) -> Production {
      self.productionsBySymbol[self.orderedSymbols[position]]!
    }

    public subscript(symbol: Symbol) -> Production? {
      self.productionsBySymbol[symbol]
    }
  }
}
