extension Expression {
  var simplified: Expression? {
    switch self {
    case .empty:
      return nil
    case .concat(let expressions):
      let simplifiedExpressions = expressions.compactMap { $0.simplified }
      switch simplifiedExpressions.count {
      case 0:
        return nil
      case 1:
        return simplifiedExpressions[0]
      default:
        return .concat(simplifiedExpressions)
      }
    case .choice(let expressions):
      let simplifiedExpressions = expressions.compactMap { $0.simplified }
      switch simplifiedExpressions.count {
      case 0:
        return nil
      case 1:
        return simplifiedExpressions[0]
      default:
        return .choice(simplifiedExpressions)
      }
    case .optional(let expression):
      return expression.simplified.map(Expression.optional)
    case .zeroOrMore(let expression):
      return expression.simplified.map(Expression.zeroOrMore)
    case .oneOrMore(let expression):
      return expression.simplified.map(Expression.oneOrMore)
    case .repeat(let min, let max, let expression):
      return expression.simplified.map { Expression.repeat(min: min, max: max, expression: $0) }
    case .group(let expression):
      return expression.simplified.map(Expression.group)
    case .characterGroup(let characterGroup):
      return .characterGroup(characterGroup)
    case .ref(let symbol):
      return .ref(symbol)
    case .terminal(let terminal):
      return .terminal(terminal)
    }
  }
}
