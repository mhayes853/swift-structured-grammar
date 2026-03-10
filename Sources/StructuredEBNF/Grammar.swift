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

  public subscript(_ identifier: Identifier) -> Production? {
    self.productionsByIdentifier[identifier]
  }

  public mutating func replaceProduction(named identifier: Identifier, with production: Production) {
    if self.productionsByIdentifier[identifier] == nil {
      self.appendIdentifierIfNeeded(identifier)
    }
    self.productionsByIdentifier[identifier] = production
  }

  public func replacingProduction(named identifier: Identifier, with production: Production) -> Self {
    var grammar = self
    grammar.replaceProduction(named: identifier, with: production)
    return grammar
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

  public mutating func homomorphMap(_ transform: (Terminal) -> Terminal?) {
  }

  public func homomorphMapped(_ transform: (Terminal) -> Terminal?) -> Self {
    self
  }

  public mutating func homomorph(_ terminal: Terminal, to replacement: Terminal) {
  }

  public func homomorphed(_ terminal: Terminal, to replacement: Terminal) -> Self {
    self
  }

  public func formatted() -> String {
    ""
  }

  private mutating func appendIdentifierIfNeeded(_ identifier: Identifier) {
    guard !self.orderedIdentifiers.contains(identifier) else { return }
    self.orderedIdentifiers.append(identifier)
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
