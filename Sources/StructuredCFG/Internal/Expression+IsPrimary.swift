extension Expression {
  var isPrimary: Bool {
    switch self {
    case .ref, .group, .terminal, .characterGroup, .custom: true
    case .empty, .concat, .choice, .optional, .repeat: false
    }
  }
}
