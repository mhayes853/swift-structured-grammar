// MARK: - Grammar

public struct Grammar: Hashable, Sendable, LanguageComponent, GrammarComponent {
  public var startingSymbol: Symbol {
    didSet {
      self.updateStartingSymbol(from: oldValue)
    }
  }

  private var orderedSymbols: [Symbol]
  private var rulesBySymbol: [Symbol: Rule]

  public var rules: Rules {
    Rules(
      orderedSymbols: self.orderedSymbols,
      rulesBySymbol: self.rulesBySymbol
    )
  }

  public var language: Language {
    Language(self)
  }

  public var grammar: Grammar {
    self
  }

  public init() {
    self.init(Rule(.root) { EmptyExpression() })
  }

  public init(_ rule: Rule) {
    self.init(startingSymbol: rule.symbol, CollectionOfOne(rule))
  }

  public init(startingSymbol: Symbol, _ rules: some Sequence<Rule>) {
    self.startingSymbol = startingSymbol
    self.orderedSymbols = [startingSymbol]
    self.rulesBySymbol = [startingSymbol: Rule(startingSymbol) { EmptyExpression() }]
    for rule in rules {
      self.append(rule)
    }
  }

  public init(startingSymbol: Symbol, @GrammarBuilder _ content: () -> [Rule]) {
    self.init(startingSymbol: startingSymbol, content())
  }

  private init(
    startingSymbol: Symbol,
    orderedSymbols: [Symbol],
    rulesBySymbol: [Symbol: Rule]
  ) {
    self.startingSymbol = startingSymbol
    self.orderedSymbols = orderedSymbols
    self.rulesBySymbol = rulesBySymbol
  }

  public func rule(for symbol: Symbol) -> Rule? {
    self.rulesBySymbol[symbol]
  }

  public func containsRule(for symbol: Symbol) -> Bool {
    self.rulesBySymbol[symbol] != nil
  }

  public subscript(_ symbol: Symbol) -> Rule? {
    self.rulesBySymbol[symbol]
  }

  public subscript(index: Int) -> Rule {
    self.rules[index]
  }

  public mutating func append(_ rule: Rule) {
    self.replaceRule(for: rule.symbol, with: rule)
  }

  public mutating func append(contentsOf rules: some Sequence<Rule>) {
    for rule in rules {
      self.append(rule)
    }
  }

  public func appending(_ rule: Rule) -> Self {
    var grammar = self
    grammar.append(rule)
    return grammar
  }

  public func appending(contentsOf rules: some Sequence<Rule>) -> Self {
    var grammar = self
    grammar.append(contentsOf: rules)
    return grammar
  }

  public mutating func removeRule(for symbol: Symbol) {
    if symbol == self.startingSymbol {
      self.rulesBySymbol[symbol] = Rule(symbol) { EmptyExpression() }
      return
    }
    self.orderedSymbols.removeAll { $0 == symbol }
    self.rulesBySymbol[symbol] = nil
  }

  public mutating func removeAll() {
    self.orderedSymbols = [self.startingSymbol]
    self.rulesBySymbol = [
      self.startingSymbol: Rule(self.startingSymbol) { EmptyExpression() }
    ]
  }

  public mutating func removeAll(where shouldBeRemoved: (Rule) -> Bool) {
    let removedSymbols = Set<Symbol>(
      self.orderedSymbols.compactMap { symbol in
        guard let rule = self.rulesBySymbol[symbol] else { return nil }
        return shouldBeRemoved(rule) ? symbol : nil
      }
    )

    self.orderedSymbols.removeAll { removedSymbols.contains($0) }
    self.rulesBySymbol = self.rulesBySymbol.filter { !removedSymbols.contains($0.key) }
    if removedSymbols.contains(self.startingSymbol) {
      self.rulesBySymbol[self.startingSymbol] = Rule(self.startingSymbol) {
        EmptyExpression()
      }
      if !self.orderedSymbols.contains(self.startingSymbol) {
        self.orderedSymbols.insert(self.startingSymbol, at: 0)
      }
    }
  }

  public mutating func replaceRule(
    for symbol: Symbol,
    with expression: some ExpressionComponent
  ) {
    self.replaceRule(for: symbol, with: Rule(symbol, expression))
  }

  public mutating func replaceRule(
    for symbol: Symbol,
    with string: String
  ) {
    self.replaceRule(for: symbol, with: Terminal(string))
  }

  public mutating func replaceRule(
    for symbol: Symbol,
    @ExpressionBuilder _ expression: () -> Expression
  ) {
    self.replaceRule(for: symbol, with: expression())
  }

  public func replacingRule(
    for symbol: Symbol,
    with expression: some ExpressionComponent
  ) -> Self {
    var grammar = self
    grammar.replaceRule(for: symbol, with: expression)
    return grammar
  }

  public func replacingRule(
    for symbol: Symbol,
    with string: String
  ) -> Self {
    var grammar = self
    grammar.replaceRule(for: symbol, with: string)
    return grammar
  }

  public func replacingRule(
    for symbol: Symbol,
    @ExpressionBuilder _ expression: () -> Expression
  ) -> Self {
    var grammar = self
    grammar.replaceRule(for: symbol, with: expression())
    return grammar
  }

  private mutating func replaceRule(for symbol: Symbol, with rule: Rule) {
    if self.rulesBySymbol[symbol] == nil {
      self.appendSymbolIfNeeded(symbol)
    }
    self.rulesBySymbol[symbol] = rule
  }

  public mutating func merge(_ grammar: Grammar) {
    for rule in grammar.rules {
      self.replaceRule(for: rule.symbol, with: rule)
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
    if self.rulesBySymbol[self.startingSymbol] == nil {
      self.rulesBySymbol[self.startingSymbol] = Rule(self.startingSymbol) {
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
    self.rulesBySymbol = self.rulesBySymbol.mapValues { production in
      Rule(
        production.symbol,
        self.homomorphed(expression: production.expression, transform: transform)
      )
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

  private func homomorphed(expression: Expression, transform: (Terminal) -> Terminal?) -> Expression
  {
    switch expression {
    case .empty:
      return .empty
    case .concat(let expressions):
      return .concat(expressions.map { self.homomorphed(expression: $0, transform: transform) })
    case .choice(let expressions):
      return .choice(expressions.map { self.homomorphed(expression: $0, transform: transform) })
    case .optional(let expression):
      return .optional(self.homomorphed(expression: expression, transform: transform))
    case .`repeat`(let repeatExpr):
      let newRepeat = Repeat(
        min: repeatExpr.min,
        max: repeatExpr.max,
        self.homomorphed(expression: repeatExpr.innerExpression, transform: transform)
      )
      return .`repeat`(newRepeat)
    case .group(let expression):
      return .group(self.homomorphed(expression: expression, transform: transform))
    case .characterGroup(let characterGroup):
      return .characterGroup(characterGroup)
    case .ref(let symbol):
      return .ref(symbol)
    case .terminal(let terminal):
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
    let rules = self.rules.compactMap { rule -> Rule? in
      guard reachableSymbols.contains(rule.symbol) else { return nil }
      return Rule(rule.symbol, self.reversed(expression: rule.expression))
    }
    return Grammar(startingSymbol: self.startingSymbol, rules)
  }

  private func reachableSymbols() -> Set<Symbol> {
    var visited = Set<Symbol>()
    var stack = [self.startingSymbol]

    while let symbol = stack.popLast() {
      guard visited.insert(symbol).inserted else { continue }
      guard let rule = self.rulesBySymbol[symbol] else { continue }
      stack.append(contentsOf: self.referencedSymbols(in: rule.expression))
    }

    return visited
  }

  private func referencedSymbols(in expression: Expression) -> [Symbol] {
    switch expression {
    case .empty:
      []
    case .concat(let expressions), .choice(let expressions):
      expressions.flatMap { self.referencedSymbols(in: $0) }
    case .optional(let expr), .group(let expr):
      self.referencedSymbols(in: expr)
    case .`repeat`(let repeatExpr):
      self.referencedSymbols(in: repeatExpr.innerExpression)
    case .characterGroup:
      []
    case .ref(let symbol):
      [symbol]
    case .terminal:
      []
    }
  }

  private func reversed(expression: Expression) -> Expression {
    switch expression {
    case .empty:
      return .empty
    case .concat(let expressions):
      return .concat(expressions.reversed().map { self.reversed(expression: $0) })
    case .choice(let expressions):
      return .choice(expressions.map { self.reversed(expression: $0) })
    case .optional(let expr):
      return .optional(self.reversed(expression: expr))
    case .`repeat`(let repeatExpr):
      let newRepeat = Repeat(
        min: repeatExpr.min,
        max: repeatExpr.max,
        self.reversed(expression: repeatExpr.innerExpression)
      )
      return .`repeat`(newRepeat)
    case .group(let expr):
      return .group(self.reversed(expression: expr))
    case .characterGroup(let characterGroup):
      return .characterGroup(characterGroup)
    case .ref(let symbol):
      return .ref(symbol)
    case .terminal(let terminal):
      return .terminal(terminal)
    }
  }
}

// MARK: - Formatting

extension Grammar {
  public func formatted(with formatter: some Formatter) throws -> String {
    try self.rules
      .map { try formatter.format(rule: $0) }
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
  }
}

// MARK: - Rules

extension Grammar {
  public struct Rules: RandomAccessCollection, Sendable {
    public typealias Element = Rule
    public typealias Index = Int

    private let orderedSymbols: [Symbol]
    private let rulesBySymbol: [Symbol: Rule]

    init(orderedSymbols: [Symbol], rulesBySymbol: [Symbol: Rule]) {
      self.orderedSymbols = orderedSymbols
      self.rulesBySymbol = rulesBySymbol
    }

    public var startIndex: Int {
      self.orderedSymbols.startIndex
    }

    public var endIndex: Int {
      self.orderedSymbols.endIndex
    }

    public subscript(position: Int) -> Rule {
      self.rulesBySymbol[self.orderedSymbols[position]]!
    }

    public subscript(symbol: Symbol) -> Rule? {
      self.rulesBySymbol[symbol]
    }
  }
}
