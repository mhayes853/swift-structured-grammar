public struct Terminal: Hashable, Sendable, ExpressibleByStringLiteral, ExpressionComponent {
  public enum Character: Hashable, Sendable {
    case character(Swift.Character)
    case hex(Unicode.Scalar)
    case unicode(Unicode.Scalar)
  }

  public let characters: [Character]

  public init(characters: [Character]) {
    self.characters = characters
  }

  public init(_ value: String) {
    self.init(characters: value.map { .character($0) })
  }

  public init(_ value: Swift.Character) {
    self.init(String(value))
  }

  public init(hex value: Unicode.Scalar) {
    self.init(hex: [value])
  }

  public init(hex value: [Unicode.Scalar]) {
    self.init(characters: value.map { .hex($0) })
  }

  public init(unicode value: Unicode.Scalar) {
    self.init(unicode: [value])
  }

  public init(unicode value: [Unicode.Scalar]) {
    self.init(characters: value.map { .unicode($0) })
  }

  public init(stringLiteral value: String) {
    self.init(value)
  }

  public var string: String {
    self.characters.reduce(into: "") { result, character in
      switch character {
      case .character(let character):
        result.append(character)
      case .hex(let scalar), .unicode(let scalar):
        result.unicodeScalars.append(scalar)
      }
    }
  }

  public var expression: Expression {
    Expression.terminal(self)
  }
}
