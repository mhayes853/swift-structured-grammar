// MARK: - Grammar

public struct Grammar: Hashable, Sendable {
  private var orderedIdentifiers: [Identifier]
  private var productionsByIdentifier: [Identifier: Production]

  public var productions: Productions {
    Productions(
      orderedIdentifiers: self.orderedIdentifiers,
      productionsByIdentifier: self.productionsByIdentifier
    )
  }

  public init() {
    self.orderedIdentifiers = [Identifier]()
    self.productionsByIdentifier = [Identifier: Production]()
  }

  public init(_ production: Production) {
    self.init(CollectionOfOne(production))
  }

  public init(_ productions: some Sequence<Production>) {
    self.init()
    for production in productions {
      self.append(production)
    }
  }

  public init(@GrammarBuilder _ content: () -> Grammar) {
    self = content()
  }

  private init(
    orderedIdentifiers: [Identifier],
    productionsByIdentifier: [Identifier: Production]
  ) {
    self.orderedIdentifiers = orderedIdentifiers
    self.productionsByIdentifier = productionsByIdentifier
  }

  public func production(named identifier: Identifier) -> Production? {
    self.productionsByIdentifier[identifier]
  }

  public func containsProduction(identifier: Identifier) -> Bool {
    self.productionsByIdentifier[identifier] != nil
  }

  public subscript(_ identifier: Identifier) -> Production? {
    self.productionsByIdentifier[identifier]
  }

  public subscript(index: Int) -> Production {
    self.productions[index]
  }

  public mutating func append(_ production: Production) {
    self.replaceProduction(named: production.identifier, with: production)
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

  public mutating func removeProduction(identifier: Identifier) {
    self.orderedIdentifiers.removeAll { $0 == identifier }
    self.productionsByIdentifier[identifier] = nil
  }

  public mutating func removeAll() {
    self.orderedIdentifiers.removeAll()
    self.productionsByIdentifier.removeAll()
  }

  public mutating func removeAll(where shouldBeRemoved: (Production) -> Bool) {
    let removedIdentifiers = Set<Identifier>(
      self.orderedIdentifiers.compactMap { identifier in
        guard let production = self.productionsByIdentifier[identifier] else { return nil }
        return shouldBeRemoved(production) ? identifier : nil
      }
    )

    self.orderedIdentifiers.removeAll { removedIdentifiers.contains($0) }
    self.productionsByIdentifier = self.productionsByIdentifier.filter { !removedIdentifiers.contains($0.key) }
  }

  public mutating func replaceProduction(
    named identifier: Identifier,
    with expression: some ConvertibleToExpression
  ) {
    self.replaceProduction(named: identifier, with: Production(identifier, expression))
  }

  public mutating func replaceProduction(
    named identifier: Identifier,
    with string: String
  ) {
    self.replaceProduction(named: identifier, with: Terminal(string))
  }

  public mutating func replaceProduction(
    named identifier: Identifier,
    @ExpressionBuilder _ expression: () -> Expression
  ) {
    self.replaceProduction(named: identifier, with: expression())
  }

  public func replacingProduction(
    named identifier: Identifier,
    with expression: some ConvertibleToExpression
  ) -> Self {
    var grammar = self
    grammar.replaceProduction(named: identifier, with: expression)
    return grammar
  }

  public func replacingProduction(
    named identifier: Identifier,
    with string: String
  ) -> Self {
    var grammar = self
    grammar.replaceProduction(named: identifier, with: string)
    return grammar
  }

  public func replacingProduction(
    named identifier: Identifier,
    @ExpressionBuilder _ expression: () -> Expression
  ) -> Self {
    var grammar = self
    grammar.replaceProduction(named: identifier, with: expression())
    return grammar
  }

  private mutating func replaceProduction(named identifier: Identifier, with production: Production) {
    if self.productionsByIdentifier[identifier] == nil {
      self.appendIdentifierIfNeeded(identifier)
    }
    self.productionsByIdentifier[identifier] = production
  }

  public mutating func merge(_ grammar: Grammar) {
    for production in grammar.productions {
      self.replaceProduction(named: production.identifier, with: production)
    }
  }

  public func merging(_ grammar: Grammar) -> Self {
    var merged = self
    merged.merge(grammar)
    return merged
  }

  private mutating func appendIdentifierIfNeeded(_ identifier: Identifier) {
    guard !self.orderedIdentifiers.contains(identifier) else { return }
    self.orderedIdentifiers.append(identifier)
  }
}

// MARK: - Homomorphism

extension Grammar {
  public mutating func homomorphMap(_ transform: (Terminal) -> Terminal?) {
    self.productionsByIdentifier = self.productionsByIdentifier.mapValues { production in
      Production(production.identifier, self.homomorphed(expression: production.expression, transform: transform))
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
    case let .ref(identifier):
      .ref(identifier)
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
          return "\(production.identifier.rawValue) = ;"
        } else {
          return "\(production.identifier.rawValue) = \(formattedExpression) ;"
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
    case let .ref(identifier):
      identifier.rawValue
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

    private let orderedIdentifiers: [Identifier]
    private let productionsByIdentifier: [Identifier: Production]

    init(orderedIdentifiers: [Identifier], productionsByIdentifier: [Identifier: Production]) {
      self.orderedIdentifiers = orderedIdentifiers
      self.productionsByIdentifier = productionsByIdentifier
    }

    public var startIndex: Int {
      self.orderedIdentifiers.startIndex
    }

    public var endIndex: Int {
      self.orderedIdentifiers.endIndex
    }

    public subscript(position: Int) -> Production {
      self.productionsByIdentifier[self.orderedIdentifiers[position]]!
    }

    public subscript(identifier: Identifier) -> Production? {
      self.productionsByIdentifier[identifier]
    }
  }
}
