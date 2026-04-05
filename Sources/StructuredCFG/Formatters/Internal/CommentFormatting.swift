// MARK: - Formatted

extension Comment {
  enum FormattingStyle: Sendable {
    case block
    case iso
    case line
    case none
  }

  func formatted(style: Comment.FormattingStyle) -> String {
    let prefixAndSuffix: (prefix: String, suffix: String)?
    switch style {
    case .block:
      prefixAndSuffix = ("/* ", " */")
    case .iso:
      prefixAndSuffix = ("(* ", " *)")
    case .line:
      prefixAndSuffix = ("// ", "")
    case .none:
      prefixAndSuffix = nil
    }

    guard let prefixAndSuffix else { return "" }

    return self.text
      .split(separator: "\n", omittingEmptySubsequences: false)
      .map { "\(prefixAndSuffix.prefix)\($0)\(prefixAndSuffix.suffix)" }
      .joined(separator: "\n")
  }
}

extension InlineComment {
  func formatted(style: Comment.FormattingStyle) -> String {
    Comment(self.text).formatted(style: style)
  }
}

// MARK: - Helpers

extension Grammar.W3CEBNFFormatter.CommentStyle {
  var sharedStyle: Comment.FormattingStyle {
    switch self {
    case .block: .block
    case .iso: .iso
    case .line: .line
    case .none: .none
    }
  }
}

extension Grammar.BNFFormatter.CommentStyle {
  var sharedStyle: Comment.FormattingStyle {
    switch self {
    case .block: .block
    case .iso: .iso
    case .line: .line
    case .none: .none
    }
  }
}
