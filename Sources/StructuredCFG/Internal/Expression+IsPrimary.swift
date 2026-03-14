extension Expression {
  var isPrimary: Bool {
    switch self {
    case .ref, .group, .terminal, .characterGroup: true
    case .empty, .concat, .choice, .optional, .zeroOrMore, .oneOrMore, .repeat: false
    }
  }
}
