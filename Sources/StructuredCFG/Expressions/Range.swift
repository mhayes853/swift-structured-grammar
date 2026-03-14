public struct Range: Hashable, Sendable, ExpressionComponent {
  public let min: Int?
  public let max: Int?
  public let expression: Expression

  public init(min: Int?, max: Int?, _ expression: some ExpressionComponent) {
    precondition(min != nil || max != nil, "Range must have at least one bound")
    if let min = min, let max = max {
      precondition(min <= max, "Range min must be less than or equal to max")
    }
    self.min = min
    self.max = max
    self.expression = .range(min: min, max: max, expression: expression.expression)
  }

  public init(exactly count: Int, _ expression: some ExpressionComponent) {
    self.init(min: count, max: count, expression)
  }

  public init(_ range: PartialRangeFrom<Int>, _ expression: some ExpressionComponent) {
    self.init(min: range.lowerBound, max: nil, expression)
  }

  public init(_ range: PartialRangeThrough<Int>, _ expression: some ExpressionComponent) {
    self.init(min: nil, max: range.upperBound, expression)
  }

  public init(_ range: PartialRangeUpTo<Int>, _ expression: some ExpressionComponent) {
    self.init(min: nil, max: range.upperBound - 1, expression)
  }

  public init(_ range: ClosedRange<Int>, _ expression: some ExpressionComponent) {
    self.init(min: range.lowerBound, max: range.upperBound, expression)
  }

  public init(_ count: Int, _ expression: some ExpressionComponent) {
    self.init(min: count, max: count, expression)
  }
}
