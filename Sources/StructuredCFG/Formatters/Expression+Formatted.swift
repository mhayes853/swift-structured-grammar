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
    try Self.format(expression: self, options: options)
  }

  private static func format(expression: Expression, options: FormatOptions) throws -> String {
    switch expression {
    case .epsilon:
      return ""

    case .terminal(let terminal):
      return terminal.formatted(options: options.terminalOptions)

    case .characterGroup(let characterGroup):
      return characterGroup.formatted(options: options.characterGroupOptions)

    case .ref(let ref):
      return options.refFormatter(ref)

    case .group(let inner):
      let innerFormatted = try Self.format(expression: inner, options: options)
      return options.groupWrapper(innerFormatted)

    case .optional(let inner):
      let innerFormatted = try Self.format(expression: inner, options: options)
      return options.optionalWrapper(innerFormatted)

    case .concat(let expressions):
      let formatted = try expressions.map { try Self.format(expression: $0, options: options) }
      return formatted.joined(separator: options.concatSeparator)

    case .choice(let expressions):
      let formatted = try expressions.map { try Self.format(expression: $0, options: options) }
      return formatted.joined(separator: options.choiceSeparator)

    case .repeat(let repeatExpr):
      let innerFormatted = try Self.format(expression: repeatExpr.innerExpression, options: options)
      if let result = options.repeatWrapper((innerFormatted, repeatExpr)) {
        return result
      }
      throw UnsupportedExpressionError("Repeat formatting requires a custom repeatWrapper")

    case .special:
      throw UnsupportedExpressionError("Special sequences are not supported")

    case .custom:
      throw UnsupportedExpressionError.customExpression
    }
  }
}
