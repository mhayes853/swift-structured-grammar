extension Expression {
  var isPrimary: Bool {
    switch self {
    case .epsilon, .ref, .group, .terminal, .characterGroup, .special, .custom: true
    case .concat, .choice, .optional, .repeat: false
    }
  }
}
