public struct Symbol: Hashable, Sendable, RawRepresentable, ExpressibleByStringLiteral {
  public static let root = Symbol(rawValue: "root")!

  public struct InvalidSymbolError: Error, Equatable, Sendable {
    public let rawValue: String
  }

  public let rawValue: String

  public init(_ rawValue: String) throws {
    guard Self.isValid(rawValue) else {
      throw InvalidSymbolError(rawValue: rawValue)
    }
    self.rawValue = rawValue
  }

  public init?(rawValue: String) {
    guard Self.isValid(rawValue) else { return nil }
    self.rawValue = rawValue
  }

  public init(stringLiteral value: String) {
    guard let symbol = Self(rawValue: value) else {
      preconditionFailure("Invalid symbol literal: \(value)")
    }
    self = symbol
  }

  private static func isValid(_ rawValue: String) -> Bool {
    guard let firstCharacter = rawValue.first else { return false }
    guard firstCharacter.isASCII else { return false }
    guard firstCharacter.isLetter else { return false }

    return rawValue.dropFirst().allSatisfy {
      $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_" || $0 == "-")
    }
  }
}
