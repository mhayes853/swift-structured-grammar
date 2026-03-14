// MARK: - Grammar

public struct Grammar: Hashable, Sendable, LanguageComponent, GrammarComponent {
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
    Language(self)
  }

  public var grammar: Grammar {
    self
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
    self.productionsBySymbol = [startingSymbol: Production(startingSymbol) { EmptyExpression() }]
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
    with expression: some ExpressionComponent
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
    with expression: some ExpressionComponent
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
      return .empty
    case let .concat(expressions):
      return .concat(expressions.map { self.homomorphed(expression: $0, transform: transform) })
    case let .choice(expressions):
      return .choice(expressions.map { self.homomorphed(expression: $0, transform: transform) })
    case let .optional(expression):
      return .optional(self.homomorphed(expression: expression, transform: transform))
    case .`repeat`(let repeatExpr):
      let newRepeat = Repeat(
        min: repeatExpr.min,
        max: repeatExpr.max,
        self.homomorphed(expression: repeatExpr.innerExpression, transform: transform)
      )
      return .`repeat`(newRepeat)
    case let .group(expression):
      return .group(self.homomorphed(expression: expression, transform: transform))
    case let .characterGroup(characterGroup):
      return .characterGroup(characterGroup)
    case let .ref(symbol):
      return .ref(symbol)
    case let .terminal(terminal):
      return transform(terminal).map(Expression.terminal) ?? .terminal(terminal)
    }
  }
}

// MARK: - Reverse

extension Grammar {
  public mutating func reverse() {
    self = self.reversed()
  }

  public func reversed() -> Self {
    let reachableSymbols = self.reachableSymbols()
    let productions = self.productions.compactMap { production -> Production? in
      guard reachableSymbols.contains(production.symbol) else { return nil }
      return Production(production.symbol, self.reversed(expression: production.expression))
    }
    return Grammar(startingSymbol: self.startingSymbol, productions)
  }

  private func reachableSymbols() -> Set<Symbol> {
    var visited = Set<Symbol>()
    var stack = [self.startingSymbol]

    while let symbol = stack.popLast() {
      guard visited.insert(symbol).inserted else { continue }
      guard let production = self.productionsBySymbol[symbol] else { continue }
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
    case let .optional(expr), let .group(expr):
      self.referencedSymbols(in: expr)
    case .`repeat`(let repeatExpr):
      self.referencedSymbols(in: repeatExpr.innerExpression)
    case .characterGroup:
      []
    case let .ref(symbol):
      [symbol]
    case .terminal:
      []
    }
  }

  private func reversed(expression: Expression) -> Expression {
    switch expression {
    case .empty:
      return .empty
    case let .concat(expressions):
      return .concat(expressions.reversed().map { self.reversed(expression: $0) })
    case let .choice(expressions):
      return .choice(expressions.map { self.reversed(expression: $0) })
    case let .optional(expr):
      return .optional(self.reversed(expression: expr))
    case .`repeat`(let repeatExpr):
      let newRepeat = Repeat(
        min: repeatExpr.min,
        max: repeatExpr.max,
        self.reversed(expression: repeatExpr.innerExpression)
      )
      return .`repeat`(newRepeat)
    case let .group(expr):
      return .group(self.reversed(expression: expr))
    case let .characterGroup(characterGroup):
      return .characterGroup(characterGroup)
    case let .ref(symbol):
      return .ref(symbol)
    case let .terminal(terminal):
      return .terminal(terminal)
    }
  }
}

// MARK: - Formatting

extension Grammar {
  public func formatted(with formatter: some Formatter) throws -> String {
    try self.productions
      .map { try formatter.format(production: $0) }
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
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
