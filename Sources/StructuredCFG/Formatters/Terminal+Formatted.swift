extension Terminal {
  struct FormatOptions: Sendable {
    enum HexFormat: Sendable {
      case none
      case gbnf
      case w3c
    }

    var quote: Swift.Character = "\""
    var escapeSequences: Bool = true
    var hexFormat: HexFormat = .none
  }

  func formatted(options: FormatOptions = FormatOptions()) throws -> String {
    let escaped = self.characters.reduce(into: "") { result, character in
      switch character {
      case .character(let character):
        if options.escapeSequences {
          switch character {
          case "\\":
            result += "\\\\"
          case "\"" where options.quote == "\"":
            result += "\\\""
          case "'" where options.quote == "'":
            result += "\\\'"
          default:
            result.append(character)
          }
        } else {
          result.append(character)
        }
      case .hex(let scalar):
        switch options.hexFormat {
        case .none:
          result += String(scalar)
        case .gbnf:
          result += "\\x"
          result += String(scalar.value, radix: 16)
        case .w3c:
          result += "#x"
          result += String(scalar.value, radix: 16)
        }
      case .unicode(let scalar):
        switch options.hexFormat {
        case .none:
          result += String(scalar)
        case .gbnf:
          result += Self.gbnfUnicodeEscape(for: scalar)
        case .w3c:
          result += String(scalar)
        }
      }
    }

    let quoteString = String(options.quote)
    return quoteString + escaped + quoteString
  }

  private static func gbnfUnicodeEscape(for scalar: Unicode.Scalar) -> String {
    let length = scalar.value <= 0xFFFF ? 4 : 8
    let prefix = scalar.value <= 0xFFFF ? "\\u" : "\\U"
    let hex = String(scalar.value, radix: 16).uppercased()
    return prefix + String(repeating: "0", count: length - hex.count) + hex
  }
}
