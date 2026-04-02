extension Terminal.Character {
  var terminal: Terminal {
    switch self {
    case .character(let character):
      Terminal(character)
    case .hex(let scalar), .unicode(let scalar):
      Terminal(Character(scalar))
    }
  }

  var asciiValue: UInt32? {
    switch self {
    case .character(let character):
      return character.asciiValue.map(UInt32.init)
    case .hex(let scalar), .unicode(let scalar):
      guard scalar.isASCII else { return nil }
      return scalar.value
    }
  }
}
