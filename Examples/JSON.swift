import StructuredCFG

/// A reusable language component that accepts JSON objects and arrays.
public struct JSON: Language.Component {
  /// Whether generated string character classes should be restricted to ASCII.
  public let asciiOnly: Bool

  public var language: Language {
    Language {
      Grammar(startingSymbol: .root) {
        Rule("sign") {
          OptionalExpression {
            Choice {
              "+"
              "-"
            }
          }
        }

        Rule("fraction") {
          OptionalExpression {
            ConcatenateExpressions {
              "."
              OneOrMore {
                CharacterGroup.digit
              }
            }
          }
        }

        Rule("exponent") {
          OptionalExpression {
            ConcatenateExpressions {
              CharacterGroup("eE")
              Ref("sign")
              OneOrMore {
                CharacterGroup.digit
              }
            }
          }
        }

        Rule("hex_digit") {
          CharacterGroup("a-fA-F0-9")
        }

        Rule("escape") {
          Choice {
            CharacterGroup("\"\\/bfnrt")
            ConcatenateExpressions {
              "u"
              Repeat(exactly: 4, Ref("hex_digit"))
            }
          }
        }

        Rule("string_characters") {
          Choice {
            ConcatenateExpressions {
              "\""
            }
            ConcatenateExpressions {
              self.stringCharacterGroup
              Ref("string_characters")
            }
            ConcatenateExpressions {
              "\\"
              Ref("escape")
              Ref("string_characters")
            }
          }
        }

        Rule("string") {
          ConcatenateExpressions {
            "\""
            Ref("string_characters")
          }
        }

        Rule("number") {
          Choice {
            ConcatenateExpressions {
              "0"
              Ref("fraction")
              Ref("exponent")
            }
            ConcatenateExpressions {
              CharacterGroup("1-9")
              ZeroOrMore { CharacterGroup.digit }
              Ref("fraction")
              Ref("exponent")
            }
            ConcatenateExpressions {
              "-"
              "0"
              Ref("fraction")
              Ref("exponent")
            }
            ConcatenateExpressions {
              "-"
              CharacterGroup("1-9")
              ZeroOrMore { CharacterGroup.digit }
              Ref("fraction")
              Ref("exponent")
            }
          }
        }

        Rule("value") {
          Choice {
            Ref("object")
            Ref("array")
            Ref("string")
            Ref("number")
            "true"
            "false"
            "null"
          }
        }

        Rule("member") {
          ConcatenateExpressions {
            Ref("string")
            ZeroOrMore { CharacterGroup.jsonWhitespace }
            ":"
            ZeroOrMore { CharacterGroup.jsonWhitespace }
            Ref("value")
          }
        }

        Rule("members") {
          ConcatenateExpressions {
            Ref("member")
            ZeroOrMore {
              GroupExpression {
                ZeroOrMore { CharacterGroup.jsonWhitespace }
                ","
                ZeroOrMore { CharacterGroup.jsonWhitespace }
                Ref("member")
              }
            }
          }
        }

        Rule("object") {
          ConcatenateExpressions {
            "{"
            ZeroOrMore { CharacterGroup.jsonWhitespace }
            OptionalExpression {
              Ref("members")
              ZeroOrMore { CharacterGroup.jsonWhitespace }
            }
            "}"
          }
        }

        Rule("elements") {
          ConcatenateExpressions {
            Ref("value")
            ZeroOrMore {
              GroupExpression {
                ZeroOrMore { CharacterGroup.jsonWhitespace }
                ","
                ZeroOrMore { CharacterGroup.jsonWhitespace }
                Ref("value")
              }
            }
          }
        }

        Rule("array") {
          ConcatenateExpressions {
            "["
            ZeroOrMore { CharacterGroup.jsonWhitespace }
            OptionalExpression {
              Ref("elements")
              ZeroOrMore { CharacterGroup.jsonWhitespace }
            }
            "]"
          }
        }

        Rule(.root) {
          Choice {
            Ref("object")
            Ref("array")
          }
        }
      }
    }
  }

  private var stringCharacterGroup: CharacterGroup {
    if self.asciiOnly {
      CharacterGroup("\\x20\\x21\\x23-\\x7E")
    } else {
      CharacterGroup("[^\\x00-\\x1F\"#x5C]")
    }
  }

  /// Creates the built-in JSON language.
  ///
  /// - Parameter asciiOnly: Whether string characters should be limited to ASCII.
  public init(asciiOnly: Bool = false) {
    self.asciiOnly = asciiOnly
  }
}

extension CharacterGroup {
  fileprivate static let jsonWhitespace = Self(" \\n\\t")
}
