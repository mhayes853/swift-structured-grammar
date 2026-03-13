public protocol ConvertibleToExpression {
  @ExpressionBuilder
  var expression: Expression { get }
}
