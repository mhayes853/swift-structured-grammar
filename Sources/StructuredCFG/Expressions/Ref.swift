/// An expression component that references another rule by symbol.
public struct Ref: Hashable, Sendable, Expression.Component {
  /// The referenced symbol.
  public let symbol: Symbol

  /// Creates a reference to another rule.
  ///
  /// - Parameter symbol: The symbol to reference.
  @inlinable
  public init(_ symbol: Symbol) {
    self.symbol = symbol
  }

  /// The referenced rule as an ``Expression``.
  @inlinable
  public var expression: Expression {
    .ref(self)
  }
}
