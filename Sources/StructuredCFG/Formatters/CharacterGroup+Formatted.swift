extension CharacterGroup {
  enum HexFormat: Sendable {
    case none
    case gbnf
    case w3c
  }

  struct FormatOptions: Sendable {
    var hexFormat: HexFormat = .none
    var useShorthands: Bool = true
    var expandRanges: Bool = true
  }

  func formatted(options: FormatOptions = FormatOptions()) throws -> String {
    if options.useShorthands {
      if let shorthand = self.shorthand(for: self) {
        return shorthand
      }
    }

    var result = self.isNegated ? "[^" : "["

    var memberIndex = 0
    while memberIndex < self.members.count {
      if options.useShorthands {
        if let shorthand = self.shorthand(
          in: self.members,
          startingAt: memberIndex,
          isNegated: self.isNegated
        ) {
          result += shorthand.value
          memberIndex += shorthand.memberCount
          continue
        }
      }

      let member = self.members[memberIndex]
      result += try self.format(member: member, hexFormat: options.hexFormat)
      memberIndex += 1
    }

    result.append("]")
    return result
  }

  private func shorthand(for characterGroup: CharacterGroup) -> String? {
    if characterGroup.isDigit {
      return "[\\d]"
    }
    if characterGroup.isWord {
      return "[\\w]"
    }
    if characterGroup.isWhitespace {
      return "[\\s]"
    }
    if characterGroup.isNonDigit {
      return "[\\D]"
    }
    if characterGroup.isNonWord {
      return "[\\W]"
    }
    if characterGroup.isNonWhitespace {
      return "[\\S]"
    }
    return nil
  }

  private func shorthand(
    in members: [Member],
    startingAt startIndex: Int,
    isNegated: Bool
  ) -> (value: String, memberCount: Int)? {
    let remainingMembers = Array(members[startIndex...])

    if !isNegated, remainingMembers.starts(with: Self.wordMembers) {
      return (value: "\\w", memberCount: Self.wordMembers.count)
    }
    if !isNegated, remainingMembers.starts(with: Self.whitespaceMembers) {
      return (value: "\\s", memberCount: Self.whitespaceMembers.count)
    }
    if remainingMembers.starts(with: Self.digitMembers) {
      return (value: isNegated ? "\\D" : "\\d", memberCount: Self.digitMembers.count)
    }
    return nil
  }

  private static let digitMembers: [Member] = [.range(.character("0"), .character("9"))]

  private static let wordMembers: [Member] = [
    .range(.character("a"), .character("z")),
    .range(.character("A"), .character("Z")),
    .range(.character("0"), .character("9")),
    .character(.character("_"))
  ]

  private static let whitespaceMembers: [Member] = [
    .character(.character(" ")),
    .escaped(.tab),
    .escaped(.newline),
    .escaped(.carriageReturn)
  ]

  private func format(member: Member, hexFormat: HexFormat) throws -> String {
    switch member {
    case .character(let character):
      return try self.format(character: character, hexFormat: hexFormat)
    case .range(let start, let end):
      return try self.format(character: start, hexFormat: hexFormat)
        + "-"
        + self.format(character: end, hexFormat: hexFormat)
    case .escaped(let escape):
      return self.format(escape: escape)
    }
  }

  private func format(character: Terminal.Character, hexFormat: HexFormat) throws -> String {
    switch character {
    case .character(let character):
      return String(character)
    case .hex(let scalar):
      switch hexFormat {
      case .none:
        return String(Swift.Character(scalar))
      case .gbnf:
        return "\\x" + String(scalar.value, radix: 16)
      case .w3c:
        return "#x" + String(scalar.value, radix: 16)
      }
    case .unicode(let scalar):
      switch hexFormat {
      case .none:
        return String(Swift.Character(scalar))
      case .gbnf:
        return Self.gbnfUnicodeEscape(for: scalar)
      case .w3c:
        return String(Swift.Character(scalar))
      }
    }
  }

  private static func gbnfUnicodeEscape(for scalar: Unicode.Scalar) -> String {
    if scalar.value <= 0xFFFF {
      return "\\u" + Self.paddedHexString(scalar.value, length: 4)
    }
    return "\\U" + Self.paddedHexString(scalar.value, length: 8)
  }

  private static func paddedHexString(_ value: UInt32) -> String {
    Self.paddedHexString(value, length: 8)
  }

  private static func paddedHexString(_ value: UInt32, length: Int) -> String {
    let hex = String(value, radix: 16).uppercased()
    let padding = String(repeating: "0", count: length - hex.count)
    return padding + hex
  }

  private func format(escape: EscapeSequence) -> String {
    switch escape {
    case .backslash:
      "\\\\"
    case .pipe:
      "\\|"
    case .period:
      "\\."
    case .hyphen:
      "\\-"
    case .caret:
      "\\^"
    case .question:
      "\\?"
    case .asterisk:
      "\\*"
    case .plus:
      "\\+"
    case .leftBrace:
      "\\{"
    case .rightBrace:
      "\\}"
    case .leftParen:
      "\\("
    case .rightParen:
      "\\)"
    case .leftBracket:
      "\\["
    case .rightBracket:
      "\\]"
    case .newline:
      "\\n"
    case .carriageReturn:
      "\\r"
    case .tab:
      "\\t"
    }
  }
}
