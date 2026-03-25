/// A literal terminal expression.
public struct Terminal: Hashable, Sendable, ExpressibleByStringLiteral, Expression.Component {
  /// A single terminal character stored either literally or by scalar representation.
  public enum Character: Hashable, Sendable {
    /// A literal Swift character.
    case character(Swift.Character)
    /// A character represented as a hex scalar for formatter output.
    case hex(Unicode.Scalar)
    /// A character represented as a Unicode scalar for formatter output.
    case unicode(Unicode.Scalar)
  }

  /// The characters that make up this terminal.
  public let characters: [Character]

  /// Creates a terminal from pre-tokenized terminal characters.
  ///
  /// - Parameter characters: The characters to store.
  public init(characters: [Character]) {
    self.characters = characters
  }

  /// Creates a terminal from a string literal value.
  ///
  /// - Parameter value: The literal terminal string.
  public init(_ value: String) {
    self.init(characters: value.map { .character($0) })
  }

  /// Creates a terminal from a single character.
  ///
  /// - Parameter value: The character to store.
  public init(_ value: Swift.Character) {
    self.init(String(value))
  }

  /// Creates a terminal from a single hex scalar.
  ///
  /// - Parameter value: The scalar to store.
  public init(hex value: Unicode.Scalar) {
    self.init(hex: [value])
  }

  /// Creates a terminal from hex scalars.
  ///
  /// - Parameter value: The scalars to store.
  public init(hex value: [Unicode.Scalar]) {
    self.init(characters: value.map { .hex($0) })
  }

  /// Creates a terminal from a single Unicode scalar.
  ///
  /// - Parameter value: The scalar to store.
  public init(unicode value: Unicode.Scalar) {
    self.init(unicode: [value])
  }

  /// Creates a terminal from Unicode scalars.
  ///
  /// - Parameter value: The scalars to store.
  public init(unicode value: [Unicode.Scalar]) {
    self.init(characters: value.map { .unicode($0) })
  }

  /// Creates a terminal from a string literal.
  ///
  /// - Parameter value: The literal terminal string.
  public init(stringLiteral value: String) {
    self.init(value)
  }

  /// The terminal contents as a Swift string.
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
