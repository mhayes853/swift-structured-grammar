/// An expression component that matches a bounded or unbounded repetition.
///
/// ```swift
/// let exactlyThreeDigits = Repeat(exactly: 3) {
///   CharacterGroup.digit
/// }
///
/// let oneToThreeLetters = Repeat(1...3) {
///   CharacterGroup("a-z")
/// }
/// ```
public struct Repeat: Hashable, Sendable, Expression.Component {
  /// The inclusive lower bound, or `nil` when there is no lower bound.
  public let min: Int?

  /// The inclusive upper bound, or `nil` when there is no upper bound.
  public let max: Int?

  /// The expression being repeated.
  public let baseExpression: Expression

  public var expression: Expression {
    .repeat(self)
  }

  /// Returns whether this repetition is equivalent to `*`.
  public var isZeroOrMore: Bool {
    self.min == 0 && self.max == nil
  }

  /// Returns whether this repetition is equivalent to `+`.
  public var isOneOrMore: Bool {
    self.min == 1 && self.max == nil
  }

  /// Creates a repetition with explicit bounds.
  ///
  /// - Parameters:
  ///   - min: The inclusive lower bound.
  ///   - max: The inclusive upper bound.
  ///   - expression: The ``Expression.Component`` to repeat.
  public init(min: Int?, max: Int?, _ expression: some Expression.Component) {
    precondition(min != nil || max != nil, "Repeat must have at least one bound")
    if let min, let max {
      precondition(min <= max, "Repeat min must be less than or equal to max")
    }
    if let max {
      precondition(max >= 0, "Repeat max must be non-negative")
    }
    self.min = min
    self.max = max
    self.baseExpression = expression.expression
  }

  /// Creates a repetition that must match an exact number of times.
  ///
  /// - Parameters:
  ///   - count: The required repetition count.
  ///   - expression: The ``Expression.Component`` to repeat.
  public init(exactly count: Int, _ expression: some Expression.Component) {
    self.init(min: count, max: count, expression)
  }

  /// Creates a repetition with only a lower bound.
  ///
  /// - Parameters:
  ///   - range: The lower-bound range.
  ///   - expression: The ``Expression.Component`` to repeat.
  public init(_ range: PartialRangeFrom<Int>, _ expression: some Expression.Component) {
    self.init(min: range.lowerBound, max: nil, expression)
  }

  /// Creates a repetition with only an inclusive upper bound.
  ///
  /// - Parameters:
  ///   - range: The upper-bound range.
  ///   - expression: The ``Expression.Component`` to repeat.
  public init(_ range: PartialRangeThrough<Int>, _ expression: some Expression.Component) {
    self.init(min: nil, max: range.upperBound, expression)
  }

  /// Creates a repetition with only an exclusive upper bound.
  ///
  /// - Parameters:
  ///   - range: The upper-bound range.
  ///   - expression: The ``Expression.Component`` to repeat.
  public init(_ range: PartialRangeUpTo<Int>, _ expression: some Expression.Component) {
    self.init(min: nil, max: range.upperBound - 1, expression)
  }

  /// Creates a repetition with inclusive lower and upper bounds.
  ///
  /// - Parameters:
  ///   - range: The closed repetition range.
  ///   - expression: The ``Expression.Component`` to repeat.
  public init(_ range: ClosedRange<Int>, _ expression: some Expression.Component) {
    self.init(min: range.lowerBound, max: range.upperBound, expression)
  }

  /// Creates a repetition that must match an exact number of times.
  ///
  /// - Parameters:
  ///   - count: The required repetition count.
  ///   - expression: The ``Expression.Component`` to repeat.
  public init(_ count: Int, _ expression: some Expression.Component) {
    self.init(min: count, max: count, expression)
  }

  /// Creates a repetition that must match an exact number of times.
  ///
  /// - Parameters:
  ///   - count: The required repetition count.
  ///   - content: A builder that produces the repeated ``Expression``.
  public init(exactly count: Int, @ExpressionBuilder _ content: () -> Expression) {
    self.init(min: count, max: count, content())
  }

  /// Creates a repetition with only a lower bound.
  ///
  /// - Parameters:
  ///   - range: The lower-bound range.
  ///   - content: A builder that produces the repeated ``Expression``.
  public init(_ range: PartialRangeFrom<Int>, @ExpressionBuilder _ content: () -> Expression) {
    self.init(min: range.lowerBound, max: nil, content())
  }

  /// Creates a repetition with only an inclusive upper bound.
  ///
  /// - Parameters:
  ///   - range: The upper-bound range.
  ///   - content: A builder that produces the repeated ``Expression``.
  public init(_ range: PartialRangeThrough<Int>, @ExpressionBuilder _ content: () -> Expression) {
    self.init(min: nil, max: range.upperBound, content())
  }

  /// Creates a repetition with only an exclusive upper bound.
  ///
  /// - Parameters:
  ///   - range: The upper-bound range.
  ///   - content: A builder that produces the repeated ``Expression``.
  public init(_ range: PartialRangeUpTo<Int>, @ExpressionBuilder _ content: () -> Expression) {
    self.init(min: nil, max: range.upperBound - 1, content())
  }

  /// Creates a repetition with inclusive lower and upper bounds.
  ///
  /// - Parameters:
  ///   - range: The closed repetition range.
  ///   - content: A builder that produces the repeated ``Expression``.
  public init(_ range: ClosedRange<Int>, @ExpressionBuilder _ content: () -> Expression) {
    self.init(min: range.lowerBound, max: range.upperBound, content())
  }

  /// Creates a repetition that must match an exact number of times.
  ///
  /// - Parameters:
  ///   - count: The required repetition count.
  ///   - content: A builder that produces the repeated ``Expression``.
  public init(_ count: Int, @ExpressionBuilder _ content: () -> Expression) {
    self.init(min: count, max: count, content())
  }
}
