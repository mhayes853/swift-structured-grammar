extension Expression {
  struct FormatOptions: Sendable {
    var terminalOptions: Terminal.FormatOptions = Terminal.FormatOptions()
    var characterGroupOptions: CharacterGroup.FormatOptions = CharacterGroup.FormatOptions()
    var concatSeparator: String = " "
    var choiceSeparator: String = " | "
    var optionalWrapper: @Sendable (String) -> String = { "[\($0)]" }
    var groupWrapper: @Sendable (String) -> String = { "(\($0))" }
    var repeatWrapper: @Sendable ((String, Repeat)) -> String? = { _ in nil }
    var refFormatter: @Sendable (Ref) -> String = { $0.symbol.rawValue }
  }

  func formatted(options: FormatOptions = FormatOptions()) throws -> String {
    try self.format(options: options)
  }

  private func format(options: FormatOptions) throws -> String {
    switch self {
    case .epsilon:
      return ""

    case .terminal(let terminal):
      return try terminal.formatted(options: options.terminalOptions)

    case .characterGroup(let characterGroup):
      return try characterGroup.formatted(options: options.characterGroupOptions)

    case .ref(let ref):
      return options.refFormatter(ref)

    case .group(let inner):
      let innerFormatted = try inner.format(options: options)
      return options.groupWrapper(innerFormatted)

    case .optional(let inner):
      let innerFormatted = try inner.format(options: options)
      return options.optionalWrapper(innerFormatted)

    case .concat(let expressions):
      let formatted = try expressions.map { try $0.format(options: options) }
      return formatted.joined(separator: options.concatSeparator)

    case .choice(let expressions):
      let formatted = try expressions.map { try $0.format(options: options) }
      return formatted.joined(separator: options.choiceSeparator)

    case .repeat(let repeatExpr):
      let innerFormatted = try repeatExpr.innerExpression.format(options: options)
      if let result = options.repeatWrapper((innerFormatted, repeatExpr)) {
        return result
      }
      throw UnsupportedExpressionError("Repeat formatting requires a custom repeatWrapper")

    case .special:
      throw UnsupportedExpressionError("Special sequences are not supported")

    case .inlineComment:
      throw UnsupportedExpressionError("Inline comments are not supported")

    case .custom:
      throw UnsupportedExpressionError.customExpression
    }
  }
}
