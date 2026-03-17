extension Expression {
  var simplified: Expression {
    switch self {
    case .empty:
      return .empty
    case .concat(let expressions):
      let simplifiedExpressions = expressions.map { $0.simplified }.filter { $0 != .empty }
      switch simplifiedExpressions.count {
      case 0:
        return .empty
      case 1:
        return simplifiedExpressions[0]
      default:
        return .concat(simplifiedExpressions)
      }
    case .choice(let expressions):
      let simplifiedExpressions = expressions.map { $0.simplified }.filter { $0 != .empty }
      switch simplifiedExpressions.count {
      case 0:
        return .empty
      case 1:
        return simplifiedExpressions[0]
      default:
        return .choice(simplifiedExpressions)
      }
    case .optional(let expression):
      let simplified = expression.simplified
      if simplified == .empty {
        return .empty
      }
      return Expression.optional(simplified)
    case .`repeat`(let repeatExpr):
      let simplified = repeatExpr.innerExpression.simplified
      if simplified == .empty {
        return .empty
      }
      let newRepeat = Repeat(min: repeatExpr.min, max: repeatExpr.max, simplified)
      return Expression.repeat(newRepeat)
    case .group(let expression):
      let simplified = expression.simplified
      if simplified == .empty {
        return .empty
      }
      return Expression.group(simplified)
    case .characterGroup(let characterGroup):
      return .characterGroup(characterGroup)
    case .ref(let ref):
      return .ref(ref)
    case .terminal(let terminal):
      return .terminal(terminal)
    case .custom(let value):
      return .custom(value)
    }
  }
}
