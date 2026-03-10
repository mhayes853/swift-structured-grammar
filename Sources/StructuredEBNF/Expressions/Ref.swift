public struct Ref: Hashable, Sendable, ConvertibleToExpression {
  public let identifier: Identifier

  public init(_ identifier: Identifier) {
    self.identifier = identifier
  }

  public var expression: Expression {
    .ref(self.identifier)
  }
}
