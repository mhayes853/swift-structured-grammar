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
    case .zeroOrMore(let expression):
      let simplified = expression.simplified
      if simplified == .empty {
        return .empty
      }
      return Expression.zeroOrMore(simplified)
    case .oneOrMore(let expression):
      let simplified = expression.simplified
      if simplified == .empty {
        return .empty
      }
      return Expression.oneOrMore(simplified)
    case .repeat(let min, let max, let expression):
      let simplified = expression.simplified
      if simplified == .empty {
        return .empty
      }
      return Expression.repeat(min: min, max: max, expression: simplified)
    case .group(let expression):
      let simplified = expression.simplified
      if simplified == .empty {
        return .empty
      }
      return Expression.group(simplified)
    case .characterGroup(let characterGroup):
      return .characterGroup(characterGroup)
    case .ref(let symbol):
      return .ref(symbol)
    case .terminal(let terminal):
      return .terminal(terminal)
    }
  }
}
