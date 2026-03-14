extension Expression {
  var isPrimary: Bool {
    switch self {
    case .ref, .group, .terminal, .characterGroup:
      return true
    case .empty, .concat, .choice, .optional, .zeroOrMore, .oneOrMore, .repeat:
      return false
    }
  }
}
