public struct Terminal: Hashable, Sendable, ExpressibleByStringLiteral, ExpressionComponent {
  public enum Part: Hashable, Sendable {
    case string(String)
    case hex([Unicode.Scalar])
  }

  public let parts: [Part]

  public init(parts: [Part]) {
    self.parts = Self.normalized(parts: parts)
  }

  public init(_ value: String) {
    self.init(parts: [.string(value)])
  }

  public init(_ value: Character) {
    self.init(String(value))
  }

  public init(hex value: Unicode.Scalar) {
    self.init(hex: [value])
  }

  public init(hex value: [Unicode.Scalar]) {
    self.init(parts: [.hex(value)])
  }

  public init(stringLiteral value: String) {
    self.init(value)
  }

  public var string: String {
    self.parts.reduce(into: "") { result, part in
      switch part {
      case .string(let string):
        result += string
      case .hex(let scalars):
        result += String(String.UnicodeScalarView(scalars))
      }
    }
  }

  public var expression: Expression {
    Expression.terminal(self)
  }

  public var character: Character? {
    guard self.string.count == 1 else { return nil }
    return self.string.first
  }

  private static func normalized(parts: [Part]) -> [Part] {
    parts.reduce(into: [Part]()) { normalized, part in
      switch part {
      case .string(let string):
        guard !string.isEmpty else { return }
        if case .string(let previous)? = normalized.last {
          normalized[normalized.count - 1] = .string(previous + string)
        } else {
          normalized.append(.string(string))
        }
      case .hex(let scalars):
        guard !scalars.isEmpty else { return }
        if case .hex(let previous)? = normalized.last {
          normalized[normalized.count - 1] = .hex(previous + scalars)
        } else {
          normalized.append(.hex(scalars))
        }
      }
    }
  }
}
