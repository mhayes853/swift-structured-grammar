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

  func formatted(options: FormatOptions = FormatOptions()) -> String {
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
      result += self.format(member: member, hexFormat: options.hexFormat)
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

  private static let digitMembers: [Member] = [.range("0", "9")]

  private static let wordMembers: [Member] = [
    .range("a", "z"),
    .range("A", "Z"),
    .range("0", "9"),
    .character("_")
  ]

  private static let whitespaceMembers: [Member] = [
    .character(" "),
    .escaped(.tab),
    .escaped(.newline),
    .escaped(.carriageReturn)
  ]

  private func format(member: Member, hexFormat: HexFormat) -> String {
    switch member {
    case .character(let char):
      return String(char)
    case .range(let start, let end):
      return String(start) + "-" + String(end)
    case .escaped(let escape):
      return self.format(escape: escape)
    case .hex(let scalar):
      switch hexFormat {
      case .none:
        return String(Character(scalar))
      case .gbnf:
        return "\\x" + String(scalar.value, radix: 16)
      case .w3c:
        return "#x" + String(scalar.value, radix: 16)
      }
    case .hexRange(let start, let end):
      switch hexFormat {
      case .none:
        return String(Character(start)) + "-" + String(Character(end))
      case .gbnf:
        return "\\x" + String(start.value, radix: 16) + "-\\x" + String(end.value, radix: 16)
      case .w3c:
        return "#x" + String(start.value, radix: 16) + "-#x" + String(end.value, radix: 16)
      }
    case .unicodeScalarRange(let start, let end):
      switch hexFormat {
      case .none, .w3c:
        return String(Character(start)) + "-" + String(Character(end))
      case .gbnf:
        let s = start.value
        let e = end.value
        let sHex = String(repeating: "0", count: 8 - String(s, radix: 16).count) + String(s, radix: 16)
        let eHex = String(repeating: "0", count: 8 - String(e, radix: 16).count) + String(e, radix: 16)
        return "\\U" + sHex.uppercased() + "-\\U" + eHex.uppercased()
      }
    }
  }

  private static func paddedHexString(_ value: UInt32) -> String {
    let hex = String(value, radix: 16).uppercased()
    let padding = String(repeating: "0", count: 8 - hex.count)
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
