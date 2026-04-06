extension Expression {
  var simplified: Expression {
    switch self {
    case .epsilon:
      return .epsilon
    case .concat(let expressions):
      let simplifiedExpressions = expressions
        .map { $0.simplified }
        .filter { $0 != .epsilon }
      switch simplifiedExpressions.count {
      case 0:
        return .epsilon
      case 1:
        return simplifiedExpressions[0]
      default:
        return .concat(simplifiedExpressions)
      }
    case .choice(let expressions):
      let simplifiedExpressions = expressions.map { $0.simplified }
      switch simplifiedExpressions.count {
      case 0:
        return .epsilon
      case 1:
        return simplifiedExpressions[0]
      default:
        return .choice(simplifiedExpressions)
      }
    case .optional(let expression):
      let simplified = expression.simplified
      if simplified == .epsilon {
        return .epsilon
      }
      return Expression.optional(simplified)
    case .`repeat`(let repeatExpr):
      let simplified = repeatExpr.baseExpression.simplified
      if simplified == .epsilon {
        return .epsilon
      }
      let newRepeat = Repeat(min: repeatExpr.min, max: repeatExpr.max, simplified)
      return Expression.repeat(newRepeat)
    case .group(let expression):
      let simplified = expression.simplified
      if simplified == .epsilon {
        return .epsilon
      }
      return Expression.group(simplified)
    case .characterGroup(let characterGroup):
      return .characterGroup(characterGroup)
    case .ref(let ref):
      return .ref(ref)
    case .special(let special):
      return .special(special)
    case .terminal(let terminal):
      return .terminal(terminal)
    case .inlineComment(let inlineComment):
      return .inlineComment(
        InlineComment(
          inlineComment.text,
          position: inlineComment.position,
          inlineComment.baseExpression.simplified
        )
      )
    case .custom(let value):
      return .custom(value)
    }
  }
}
