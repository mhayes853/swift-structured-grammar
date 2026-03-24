/// A sequence wrapper that exposes the rules of an optional grammar component.
public struct OptionalRules<Base: Sequence<Rule>>: Sequence {
  private let base: Base?

  init(_ base: Base?) {
    self.base = base
  }

  public func makeIterator() -> Iterator {
    Iterator(self.base?.makeIterator())
  }

  public struct Iterator: IteratorProtocol {
    private var base: Base.Iterator?

    init(_ base: Base.Iterator?) {
      self.base = base
    }

    public mutating func next() -> Rule? {
      self.base?.next()
    }
  }
}

extension Optional: GrammarComponent where Wrapped: GrammarComponent {
  public var rules: OptionalRules<Wrapped.Rules> {
    return OptionalRules(self?.rules)
  }
}
