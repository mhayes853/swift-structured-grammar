extension Optional: Expression.Component where Wrapped: Expression.Component {
  @inlinable
  public var expression: Expression {
    self.map { $0.expression } ?? .epsilon
  }
}
