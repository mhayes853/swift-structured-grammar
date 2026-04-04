// MARK: - CharacterGroup

/// A character-class expression component.
///
/// Character groups can be created from parsed class syntax like `"a-z0-9"` or from
/// predefined presets such as ``digit``, `word`, and `whitespace`.
///
/// ```swift
/// let identifierHead = CharacterGroup("a-zA-Z_")
/// let digits = CharacterGroup.digit
/// let nonWhitespace = CharacterGroup.whitespace.negated()
/// ```
public struct CharacterGroup: Hashable, Sendable, Expression.Component {
  /// Whether the character group is negated.
  public let isNegated: Bool

  /// The members that make up this character group.
  ///
  /// This is `nil` when the group is represented semantically rather than as explicit members,
  /// such as ``all``.
  public var members: [Member]? {
    switch self.storage {
    case .members(let members):
      members
    case .all:
      nil
    }
  }

  private let storage: Storage

  /// Creates a character group from explicit members.
  ///
  /// - Parameters:
  ///   - isNegated: Whether the group should be negated.
  ///   - members: The members contained in the group.
  public init(isNegated: Bool, members: [Member]) {
    self.init(isNegated: isNegated, storage: .members(members))
  }

  private init(isNegated: Bool, storage: Storage) {
    self.isNegated = isNegated
    self.storage = storage
  }

  /// Parses a character group from bracketed or unbracketed class syntax.
  ///
  /// - Parameter string: The character-class text to parse.
  /// - Throws: ``ParseError`` when the class syntax is invalid.
  @_disfavoredOverload
  public init(_ string: String) throws {
    let processedString: String
    switch (string.hasPrefix("["), Self.hasUnescapedTrailingClosingBracket(string)) {
    case (false, false):
      processedString = "[" + string + "]"
    case (true, true):
      processedString = string
    default:
      throw ParseError.mustBeFullyBracketedOrUnbracketed
    }

    let parsed = try Self.parse(processedString)
    self.init(isNegated: parsed.isNegated, members: parsed.members)
  }

  /// Parses a character group from a static string literal.
  ///
  /// Invalid input triggers a runtime failure.
  ///
  /// - Parameter string: The character-class text to parse.
  public init(_ string: StaticString) {
    do {
      try self.init(String(describing: string))
    } catch {
      fatalError("Unable to parse CharacterGroup from '\(string)': \(error)")
    }
  }

  /// Creates a character group from a closed character range.
  ///
  /// - Parameter range: The range of characters to include.
  public init(_ range: ClosedRange<Character>) {
    self.init(
      isNegated: false,
      members: [.range(.character(range.lowerBound), .character(range.upperBound))]
    )
  }

  public var expression: Expression {
    Expression.characterGroup(self)
  }

  /// Returns a negated copy of this character group.
  ///
  /// - Returns: A ``CharacterGroup`` with the opposite negation state.
  public func negated() -> CharacterGroup {
    CharacterGroup(isNegated: !self.isNegated, storage: self.storage)
  }

  /// Returns whether this group semantically matches all characters.
  ///
  /// This is `true` for ``all`` and for negated forms derived from it.
  public var isAllCharacters: Bool {
    if case .all = self.storage {
      true
    } else {
      false
    }
  }

  /// A character group matching ASCII decimal digits.
  public static var digit: Self {
    Self(isNegated: false, members: Self.digitMembers)
  }

  /// A character group matching ASCII word characters.
  public static var word: Self {
    Self(isNegated: false, members: Self.wordMembers)
  }

  /// A character group matching common whitespace characters.
  public static var whitespace: Self {
    Self(isNegated: false, members: Self.whitespaceMembers)
  }

  /// A character group matching every Unicode scalar.
  public static var all: Self {
    Self(isNegated: false, storage: .all)
  }

  /// Returns whether this group matches the predefined digit class.
  public var isDigit: Bool {
    self.matches(isNegated: false, members: Self.digitMembers)
  }

  /// Returns whether this group matches the predefined word class.
  public var isWord: Bool {
    self.matches(isNegated: false, members: Self.wordMembers)
  }

  /// Returns whether this group matches the predefined whitespace class.
  public var isWhitespace: Bool {
    self.matches(isNegated: false, members: Self.whitespaceMembers)
  }

  /// Returns whether this group matches the negated digit class.
  public var isNonDigit: Bool {
    self.matches(isNegated: true, members: Self.digitMembers)
  }

  /// Returns whether this group matches the negated word class.
  public var isNonWord: Bool {
    self.matches(isNegated: true, members: Self.wordMembers)
  }

  /// Returns whether this group matches the negated whitespace class.
  public var isNonWhitespace: Bool {
    self.matches(isNegated: true, members: Self.whitespaceMembers)
  }

  private static func parse(_ string: String) throws -> (isNegated: Bool, members: [Member]) {
    guard string.hasPrefix("[") else {
      throw ParseError.mustStartWithOpeningBracket
    }

    var isNegated = false
    var content = String(string.dropFirst())

    if content.hasPrefix("^") {
      isNegated = true
      content = String(content.dropFirst())
    }

    guard content.hasSuffix("]") else {
      throw ParseError.mustEndWithClosingBracket
    }
    content = String(content.dropLast())

    if !isNegated {
      switch content {
      case #"\D"#:
        return (true, Self.digitMembers)
      case #"\W"#:
        return (true, Self.wordMembers)
      case #"\S"#:
        return (true, Self.whitespaceMembers)
      default:
        break
      }
    }

    var members = [Member]()
    let characters = Array(content)
    var i = 0

    while i < characters.count {
      let character = characters[i]
      if character == "\\" {
        let (newMembers, newIndex) = try parseEscapeSequence(
          characters: characters,
          index: i,
          isNegated: isNegated,
          existingMembers: members
        )
        members.append(contentsOf: newMembers)
        i = newIndex
      } else if character == "#" && i + 1 < characters.count && characters[i + 1] == "x" {
        let (newMembers, newIndex) = try parseHexMember(characters: characters, index: i)
        members.append(contentsOf: newMembers)
        i = newIndex
      } else if i + 2 < characters.count && characters[i + 1] == "-" {
        let (newMembers, newIndex) = try parseCharacterRange(characters: characters, index: i)
        members.append(contentsOf: newMembers)
        i = newIndex
      } else {
        members.append(.character(.character(character)))
        i += 1
      }
    }

    return (isNegated, members)
  }

  private static func parseEscapeSequence(
    characters: [Character],
    index: Int,
    isNegated: Bool,
    existingMembers: [Member]
  ) throws -> (members: [Member], index: Int) {
    var members = [Member]()

    guard index + 1 < characters.count else {
      throw ParseError.cannotEndWithEscape
    }

    let escapedCharacter = characters[index + 1]
    switch escapedCharacter {
    case "d":
      members.append(contentsOf: Self.digitMembers)
    case "w":
      members.append(contentsOf: Self.wordMembers)
    case "s":
      members.append(contentsOf: Self.whitespaceMembers)
    case "D":
      guard !isNegated, existingMembers.isEmpty, index + 2 == characters.count else {
        throw ParseError.negatedPredefinedClassesMustBeStandalone
      }
      members.append(contentsOf: Self.digitMembers)
    case "W":
      guard !isNegated, existingMembers.isEmpty, index + 2 == characters.count else {
        throw ParseError.negatedPredefinedClassesMustBeStandalone
      }
      members.append(contentsOf: Self.wordMembers)
    case "S":
      guard !isNegated, existingMembers.isEmpty, index + 2 == characters.count else {
        throw ParseError.negatedPredefinedClassesMustBeStandalone
      }
      members.append(contentsOf: Self.whitespaceMembers)
    case "n":
      members.append(.escaped(EscapeSequence("\n")))
    case "r":
      members.append(.escaped(EscapeSequence("\r")))
    case "t":
      members.append(.escaped(EscapeSequence("\t")))
    case "x":
      return try parseHexEscape(characters: characters, index: index)
    case "u", "U":
      return try parseUnicodeEscape(characters: characters, index: index)
    default:
      members.append(.escaped(EscapeSequence(escapedCharacter)))
    }
    return (members, index + 2)
  }

  private static func parseHexEscape(characters: [Character], index: Int) throws -> (
    members: [Member], index: Int
  ) {
    guard index + 2 < characters.count else {
      throw ParseError.incompleteHexEscape
    }
    let hexStart = index + 2
    var hexEnd = hexStart
    while hexEnd < characters.count && characters[hexEnd].isHexDigit {
      hexEnd += 1
    }
    guard hexEnd > hexStart else {
      throw ParseError.invalidHexEscape
    }
    let hexString = String(characters[hexStart..<hexEnd])
    guard let scalar = Self.parseHex(hexString) else {
      throw ParseError.invalidHexValue(hexString)
    }
    return try Self.parseMemberOrRange(
      characters: characters,
      start: .hex(scalar),
      index: hexEnd,
      allowedEscapes: ["x", "u", "U"]
    )
  }

  private static func parseUnicodeEscape(characters: [Character], index: Int) throws -> (
    members: [Member], index: Int
  ) {
    let escapedCharacter = characters[index + 1]
    let expectedDigits = escapedCharacter == "u" ? 4 : 8

    guard index + 1 + expectedDigits < characters.count else {
      throw ParseError.incompleteHexEscape
    }

    let hexStart = index + 2
    let hexEnd = hexStart + expectedDigits
    let hexString = String(characters[hexStart..<hexEnd])

    guard hexString.allSatisfy({ $0.isHexDigit }) else {
      throw ParseError.invalidHexEscape
    }

    guard let startScalar = Self.parseHex(hexString) else {
      throw ParseError.invalidHexValue(hexString)
    }

    return try Self.parseMemberOrRange(
      characters: characters,
      start: .unicode(startScalar),
      index: hexEnd,
      allowedEscapes: ["x", "u", "U"]
    )
  }

  private static func parseHexMember(characters: [Character], index: Int) throws -> (
    members: [Member], index: Int
  ) {
    let hexStart = index + 2
    var hexEnd = hexStart
    while hexEnd < characters.count && characters[hexEnd].isHexDigit {
      hexEnd += 1
    }
    guard hexEnd > hexStart else {
      throw ParseError.invalidHexCharacter
    }

    let hexString = String(characters[hexStart..<hexEnd])
    guard let scalar = Self.parseHex(hexString) else {
      throw ParseError.invalidHexValue(hexString)
    }
    return try Self.parseMemberOrRange(
      characters: characters,
      start: .hex(scalar),
      index: hexEnd,
      allowedHexMember: true,
      allowedEscapes: ["x", "u", "U"]
    )
  }

  private static func parseCharacterRange(characters: [Character], index: Int) throws -> (
    members: [Member], index: Int
  ) {
    let startCharacter = characters[index]
    if startCharacter == "-" {
      return ([.character(.character(characters[index]))], index + 1)
    }
    return try Self.parseMemberOrRange(
      characters: characters,
      start: .character(startCharacter),
      index: index + 1,
      allowedHexMember: true,
      allowedEscapes: ["x", "u", "U"],
      treatsHyphenEndpointAsLiteral: true
    )
  }

  private static func parseMemberOrRange(
    characters: [Character],
    start: Terminal.Character,
    index: Int,
    allowedHexMember: Bool = false,
    allowedEscapes: Set<Character>,
    treatsHyphenEndpointAsLiteral: Bool = false
  ) throws -> (members: [Member], index: Int) {
    let rangeEndpoint = try Self.parseRangeEndpoint(
      characters: characters,
      index: index,
      allowedHexMember: allowedHexMember,
      allowedEscapes: allowedEscapes
    )
    if let (endCharacter, rangeEnd) = rangeEndpoint {
      if treatsHyphenEndpointAsLiteral, case .character("-") = endCharacter {
        return ([.character(start)], index)
      }
      try Self.validateRange(start: start, end: endCharacter)
      return ([.range(start, endCharacter)], rangeEnd)
    }
    return ([.character(start)], index)
  }

  private static func parseHex(_ string: String) -> Unicode.Scalar? {
    guard !string.isEmpty else { return nil }
    guard let value = UInt32(string, radix: 16) else { return nil }
    return Unicode.Scalar(value)
  }

  private static func parseRangeEndpoint(
    characters: [Character],
    index: Int,
    allowedHexMember: Bool = false,
    allowedEscapes: Set<Character>
  ) throws -> (Terminal.Character, Int)? {
    guard index < characters.count, characters[index] == "-" else {
      return nil
    }

    let start = index + 1
    guard start < characters.count else {
      return nil
    }

    let character = characters[start]
    if character == "#" {
      guard allowedHexMember, start + 1 < characters.count, characters[start + 1] == "x" else {
        return nil
      }
      let hexStart = start + 2
      var hexEnd = hexStart
      while hexEnd < characters.count && characters[hexEnd].isHexDigit {
        hexEnd += 1
      }
      guard hexEnd > hexStart else {
        throw ParseError.invalidHexCharacter
      }
      let hexString = String(characters[hexStart..<hexEnd])
      guard let scalar = Self.parseHex(hexString) else {
        throw ParseError.invalidHexValue(hexString)
      }
      return (.hex(scalar), hexEnd)
    }

    if character == "\\" {
      guard start + 1 < characters.count else {
        throw ParseError.cannotEndWithEscape
      }
      let escape = characters[start + 1]
      guard allowedEscapes.contains(escape) else {
        return nil
      }
      switch escape {
      case "x":
        let hexStart = start + 2
        var hexEnd = hexStart
        while hexEnd < characters.count && characters[hexEnd].isHexDigit {
          hexEnd += 1
        }
        guard hexEnd > hexStart else {
          throw ParseError.invalidHexEscape
        }
        let hexString = String(characters[hexStart..<hexEnd])
        guard let scalar = Self.parseHex(hexString) else {
          throw ParseError.invalidHexValue(hexString)
        }
        return (.hex(scalar), hexEnd)
      case "u", "U":
        let expectedDigits = escape == "u" ? 4 : 8
        guard start + 1 + expectedDigits < characters.count else {
          throw ParseError.incompleteHexEscape
        }
        let hexStart = start + 2
        let hexEnd = hexStart + expectedDigits
        let hexString = String(characters[hexStart..<hexEnd])
        guard hexString.allSatisfy({ $0.isHexDigit }) else {
          throw ParseError.invalidHexEscape
        }
        guard let scalar = Self.parseHex(hexString) else {
          throw ParseError.invalidHexValue(hexString)
        }
        return (.unicode(scalar), hexEnd)
      default:
        return nil
      }
    }

    return (.character(character), start + 1)
  }

  private static func validateRange(start: Terminal.Character, end: Terminal.Character) throws {
    guard let startValue = Self.scalarValue(for: start), let endValue = Self.scalarValue(for: end)
    else {
      return
    }

    guard startValue <= endValue else {
      throw ParseError.invalidRangeStartGreaterThanEnd
    }
  }

  private static func scalarValue(for character: Terminal.Character) -> UInt32? {
    switch character {
    case .character(let character):
      let unicodeScalars = String(character).unicodeScalars
      guard unicodeScalars.count == 1 else { return nil }
      return unicodeScalars.first?.value
    case .hex(let scalar), .unicode(let scalar):
      return scalar.value
    }
  }

  private static func hasUnescapedTrailingClosingBracket(_ string: String) -> Bool {
    guard string.last == "]" else {
      return false
    }

    var trailingBackslashCount = 0
    for character in string.dropLast().reversed() {
      guard character == "\\" else {
        break
      }
      trailingBackslashCount += 1
    }

    return trailingBackslashCount.isMultiple(of: 2)
  }

  /// A member of a character group.
  public enum Member: Hashable, Sendable {
    /// A single character member.
    case character(Terminal.Character)

    /// A closed character range member.
    case range(Terminal.Character, Terminal.Character)

    /// An escaped metacharacter or control character member.
    case escaped(EscapeSequence)
  }

  private enum Storage: Hashable, Sendable {
    case members([Member])
    case all
  }

  /// An escaped source character in a character group.
  public struct EscapeSequence: Hashable, Sendable {
    /// The escaped source character.
    public let character: Character

    /// Creates an escape sequence from an escaped character.
    ///
    /// - Parameter character: The escaped source character.
    public init(_ character: Character) {
      self.character = character
    }

    /// Returns whether this escape sequence is `\\`.
    public var isBackslash: Bool {
      self.character == "\\"
    }

    /// Returns whether this escape sequence is `\|`.
    public var isPipe: Bool {
      self.character == "|"
    }

    /// Returns whether this escape sequence is `\.`.
    public var isPeriod: Bool {
      self.character == "."
    }

    /// Returns whether this escape sequence is `\-`.
    public var isHyphen: Bool {
      self.character == "-"
    }

    /// Returns whether this escape sequence is `\^`.
    public var isCaret: Bool {
      self.character == "^"
    }

    /// Returns whether this escape sequence is `\?`.
    public var isQuestion: Bool {
      self.character == "?"
    }

    /// Returns whether this escape sequence is `\*`.
    public var isAsterisk: Bool {
      self.character == "*"
    }

    /// Returns whether this escape sequence is `\+`.
    public var isPlus: Bool {
      self.character == "+"
    }

    /// Returns whether this escape sequence is `\{`.
    public var isLeftBrace: Bool {
      self.character == "{"
    }

    /// Returns whether this escape sequence is `\}`.
    public var isRightBrace: Bool {
      self.character == "}"
    }

    /// Returns whether this escape sequence is `\(`.
    public var isLeftParen: Bool {
      self.character == "("
    }

    /// Returns whether this escape sequence is `\)`.
    public var isRightParen: Bool {
      self.character == ")"
    }

    /// Returns whether this escape sequence is `\[`.
    public var isLeftBracket: Bool {
      self.character == "["
    }

    /// Returns whether this escape sequence is `\]`.
    public var isRightBracket: Bool {
      self.character == "]"
    }

    /// Returns whether this escape sequence is `\n`.
    public var isNewline: Bool {
      self.character == "\n"
    }

    /// Returns whether this escape sequence is `\r`.
    public var isCarriageReturn: Bool {
      self.character == "\r"
    }

    /// Returns whether this escape sequence is `\t`.
    public var isTab: Bool {
      self.character == "\t"
    }
  }

  static let digitMembers: [Member] = [.range(.character("0"), .character("9"))]

  static let wordMembers: [Member] = [
    .range(.character("a"), .character("z")),
    .range(.character("A"), .character("Z")),
    .range(.character("0"), .character("9")),
    .character(.character("_"))
  ]

  static let whitespaceMembers: [Member] = [
    .character(.character(" ")),
    .escaped(EscapeSequence("\t")),
    .escaped(EscapeSequence("\n")),
    .escaped(EscapeSequence("\r"))
  ]

  private func matches(isNegated: Bool, members: [Member]) -> Bool {
    self.isNegated == isNegated && self.memberCounts == Self.memberCounts(members)
  }

  private var memberCounts: [Member: Int] {
    guard let members = self.members else {
      return [:]
    }
    return members.reduce(into: [Member: Int]()) { counts, member in
      counts[member, default: 0] += 1
    }
  }

  private static func memberCounts(_ members: [Member]) -> [Member: Int] {
    members.reduce(into: [Member: Int]()) { counts, member in
      counts[member, default: 0] += 1
    }
  }
}

// MARK: - CharacterGroup.ParseError

extension CharacterGroup {
  /// An error produced while parsing a character group string.
  public struct ParseError: Error, Hashable, Sendable {
    /// A stable error code describing a parse failure category.
    public struct Code: RawRepresentable, Hashable, Sendable {
      /// The raw string code.
      public let rawValue: String

      /// Creates an error code from a raw string.
      ///
      /// - Parameter rawValue: The raw code value.
      public init(rawValue: String) {
        self.rawValue = rawValue
      }

      /// The input mixed bracketed and unbracketed forms.
      public static let mustBeFullyBracketedOrUnbracketed = Self(
        rawValue: "must_be_fully_bracketed_or_unbracketed"
      )

      /// The input was missing an opening bracket.
      public static let mustStartWithOpeningBracket = Self(
        rawValue: "must_start_with_opening_bracket"
      )

      /// The input was missing a closing bracket.
      public static let mustEndWithClosingBracket = Self(
        rawValue: "must_end_with_closing_bracket"
      )

      /// The input ended with an incomplete escape sequence.
      public static let cannotEndWithEscape = Self(rawValue: "cannot_end_with_escape")

      /// A negated predefined class appeared alongside other members.
      public static let negatedPredefinedClassesMustBeStandalone = Self(
        rawValue: "negated_predefined_classes_must_be_standalone"
      )

      /// XML name class syntax was encountered.
      public static let xmlNameClassesAreNotSupported = Self(
        rawValue: "xml_name_classes_are_not_supported"
      )

      /// A hex escape ended before all digits were read.
      public static let incompleteHexEscape = Self(rawValue: "incomplete_hex_escape")

      /// A hex escape had an invalid prefix.
      public static let invalidHexEscape = Self(rawValue: "invalid_hex_escape")

      /// A hex digit was invalid.
      public static let invalidHexCharacter = Self(rawValue: "invalid_hex_character")

      /// A range started after it ended.
      public static let invalidRangeStartGreaterThanEnd = Self(
        rawValue: "invalid_range_start_greater_than_end"
      )

      /// A parsed hex value could not be converted to a scalar.
      public static let invalidHexValue = Self(rawValue: "invalid_hex_value")
    }

    /// The stable error code.
    public let code: Code

    /// A human-readable error message.
    public let message: String

    /// Creates a parse error.
    ///
    /// - Parameters:
    ///   - code: The stable error code.
    ///   - message: A human-readable description.
    public init(code: Code, message: String) {
      self.code = code
      self.message = message
    }

    /// The input mixed bracketed and unbracketed forms.
    public static let mustBeFullyBracketedOrUnbracketed = Self(
      code: .mustBeFullyBracketedOrUnbracketed,
      message: "Character groups must be fully bracketed or unbracketed"
    )

    /// The input was missing an opening bracket.
    public static let mustStartWithOpeningBracket = Self(
      code: .mustStartWithOpeningBracket,
      message: "Character groups must start with '['"
    )

    /// The input was missing a closing bracket.
    public static let mustEndWithClosingBracket = Self(
      code: .mustEndWithClosingBracket,
      message: "Character groups must end with ']'"
    )

    /// The input ended with an incomplete escape sequence.
    public static let cannotEndWithEscape = Self(
      code: .cannotEndWithEscape,
      message: "Character groups cannot end with an escape"
    )

    /// A negated predefined class appeared alongside other members.
    public static let negatedPredefinedClassesMustBeStandalone = Self(
      code: .negatedPredefinedClassesMustBeStandalone,
      message: "Negated predefined classes are only supported as standalone groups"
    )

    /// A hex escape ended before all digits were read.
    public static let incompleteHexEscape = Self(
      code: .incompleteHexEscape,
      message: "Incomplete hex escape"
    )

    /// A hex escape had an invalid prefix.
    public static let invalidHexEscape = Self(
      code: .invalidHexEscape,
      message: "Invalid hex escape"
    )

    /// A hex digit was invalid.
    public static let invalidHexCharacter = Self(
      code: .invalidHexCharacter,
      message: "Invalid hex character"
    )

    /// A range started after it ended.
    public static let invalidRangeStartGreaterThanEnd = Self(
      code: .invalidRangeStartGreaterThanEnd,
      message: "Invalid range: start > end"
    )

    /// Creates an error for a malformed hex scalar value.
    ///
    /// - Parameter value: The invalid hex value.
    /// - Returns: A parse error describing the invalid value.
    public static func invalidHexValue(_ value: String) -> Self {
      Self(code: .invalidHexValue, message: "Invalid hex value: \(value)")
    }
  }
}
