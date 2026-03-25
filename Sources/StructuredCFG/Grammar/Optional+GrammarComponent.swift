/// A sequence wrapper that exposes the statements of an optional grammar component.
public struct OptionalStatements<Base: Sequence<Grammar.Statement>>: Sequence {
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

    public mutating func next() -> Grammar.Statement? {
      self.base?.next()
    }
  }
}

extension Optional: Grammar.Component where Wrapped: Grammar.Component {
  public var statements: OptionalStatements<Wrapped.Statements> {
    return OptionalStatements(self?.statements)
  }
}
