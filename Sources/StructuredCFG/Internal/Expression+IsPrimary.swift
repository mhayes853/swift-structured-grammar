extension Expression {
  var isPrimary: Bool {
    switch self {
    case .emptySequence, .ref, .group, .terminal, .characterGroup, .special, .custom: true
    case .empty, .concat, .choice, .optional, .repeat: false
    }
  }
}
