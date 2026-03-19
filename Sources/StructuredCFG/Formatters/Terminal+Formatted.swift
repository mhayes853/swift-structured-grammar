extension Terminal {
  struct FormatOptions: Sendable {
    enum HexFormat: Sendable {
      case none
      case gbnf
      case w3c
    }

    var quote: Character = "\""
    var escapeSequences: Bool = true
    var hexFormat: HexFormat = .none
  }

  func formatted(options: FormatOptions = FormatOptions()) -> String {
    let escaped = self.parts.reduce(into: "") { result, part in
      switch part {
      case .string(let string):
        if options.escapeSequences {
          result += string.map { character in
            switch character {
            case "\\":
              "\\\\"
            case "\"" where options.quote == "\"":
              "\\\""
            case "'" where options.quote == "'":
              "\\\'"
            default:
              String(character)
            }
          }.joined()
        } else {
          result += string
        }
      case .hex(let scalars):
        switch options.hexFormat {
        case .none:
          result += String(String.UnicodeScalarView(scalars))
        case .gbnf:
          result += scalars.reduce(into: "") { hexResult, scalar in
            hexResult += "\\x"
            hexResult += String(scalar.value, radix: 16)
          }
        case .w3c:
          result += scalars.reduce(into: "") { hexResult, scalar in
            hexResult += "#x"
            hexResult += String(scalar.value, radix: 16)
          }
        }
      }
    }

    let quoteString = String(options.quote)
    return quoteString + escaped + quoteString
  }
}
