public struct JSONLanguage: LanguageComponent {
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

        Rule("characters_item") {
          CharactersExpression(
            name: "characters_item",
            allowedCharacters: self.stringCharacterGroup,
            ending1: Epsilon(),
            ending2: CharacterGroup(",#x5D")
          )
        }

        Rule("characters_and_embrace") {
          CharactersExpression(
            name: "characters_and_embrace",
            allowedCharacters: self.stringCharacterGroup,
            ending1: ConcatenateExpressions {
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              "}"
            },
            ending2: CharacterGroup("},")
          )
        }

        Rule("characters_and_comma") {
          CharactersExpression(
            name: "characters_and_comma",
            allowedCharacters: self.stringCharacterGroup,
            ending1: ConcatenateExpressions {
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              ","
            },
            ending2: Terminal("\"")
          )
        }

        Rule("characters_and_colon") {
          CharactersExpression(
            name: "characters_and_colon",
            allowedCharacters: self.stringCharacterGroup,
            ending1: ConcatenateExpressions {
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              ":"
            },
            ending2: CharacterGroup("\"{[0-9tfn-")
          )
        }

        Rule("elements_rest") {
          OptionalExpression {
            ConcatenateExpressions {
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              ","
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              Ref("elements")
            }
          }
        }

        Rule("elements") {
          Choice {
            JSONElement {
              "{"
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              Ref("members_and_embrace")
            }
            JSONElement {
              "["
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              Ref("elements_or_embrace")
            }
            JSONElement {
              "\""
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              Ref("characters_item")
            }
            JSONElement {
              "0"
              Ref("fraction")
              Ref("exponent")
            }
            JSONElement {
              CharacterGroup("1-9")
              ZeroOrMore { CharacterGroup.digit }
              Ref("fraction")
              Ref("exponent")
            }
            JSONElement {
              "-"
              CharacterGroup.digit
              Ref("fraction")
              Ref("exponent")
            }
            JSONElement {
              "-"
              CharacterGroup("1-9")
              ZeroOrMore { CharacterGroup.digit }
              Ref("fraction")
              Ref("exponent")
            }
            JSONElement { "true" }
            JSONElement { "false" }
            JSONElement { "null" }
          }
        }

        Rule("elements_or_embrace") {
          Choice {
            JSONElement(withEmbrace: true) {
              "{"
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              Ref("members_and_embrace")
            }
            JSONElement(withEmbrace: true) {
              "["
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              Ref("elements_or_embrace")
            }
            JSONElement(withEmbrace: true) {
              "\""
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              Ref("characters_item")
            }
            JSONElement(withEmbrace: true) {
              "0"
              Ref("fraction")
              Ref("exponent")
            }
            JSONElement(withEmbrace: true) {
              CharacterGroup("1-9")
              ZeroOrMore { CharacterGroup.digit }
              Ref("fraction")
              Ref("exponent")
            }
            JSONElement(withEmbrace: true) {
              "-"
              CharacterGroup.digit
              Ref("fraction")
              Ref("exponent")
            }
            JSONElement(withEmbrace: true) {
              "-"
              CharacterGroup("1-9")
              ZeroOrMore { CharacterGroup.digit }
              Ref("fraction")
              Ref("exponent")
            }
            JSONElement(withEmbrace: true) { "true" }
            JSONElement(withEmbrace: true) { "false" }
            JSONElement(withEmbrace: true) { "null" }
            "]"
          }
        }

        Rule("member_suffix_suffix") {
          Choice {
            "}"
            ConcatenateExpressions {
              ","
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              "\""
              Ref("characters_and_colon")
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              Ref("members_suffix")
            }
          }
          JSONMembersEnding()
        }

        Rule("members_suffix") {
          Choice {
            ConcatenateExpressions {
              Ref("value_non_str")
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              Ref("member_suffix_suffix")
            }
            ConcatenateExpressions {
              "\""
              Ref("characters_and_embrace")
            }
            ConcatenateExpressions {
              "\""
              Ref("characters_and_comma")
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              "\""
              Ref("characters_and_colon")
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              Ref("members_suffix")
            }
          }
          JSONMembersEnding()
        }

        Rule("members_and_embrace") {
          Choice {
            ConcatenateExpressions {
              "\""
              Ref("characters_and_colon")
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              Ref("members_suffix")
            }
            "}"
          }
          JSONMembersEnding()
        }

        Rule("value_non_str") {
          Choice {
            ConcatenateExpressions {
              "{"
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              Ref("members_and_embrace")
            }
            ConcatenateExpressions {
              "["
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              Ref("elements_or_embrace")
            }
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
              CharacterGroup.digit
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
            "true"
            "false"
            "null"
          }
          ConcatenateExpressions {
            "="
            ZeroOrMore { CharacterGroup.jsonWhitespace }
            Ref("member_suffix_suffix")
          }
        }

        Rule(.root) {
          Choice {
            ConcatenateExpressions {
              "{"
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              Ref("members_and_embrace")
            }
            ConcatenateExpressions {
              "["
              ZeroOrMore { CharacterGroup.jsonWhitespace }
              Ref("elements_or_embrace")
            }
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

  public init(asciiOnly: Bool = false) {
    self.asciiOnly = asciiOnly
  }
}

// MARK: - Helpers

private struct CharactersExpression<
  E: ExpressionComponent,
  E2: ExpressionComponent
>: ExpressionComponent {
  let name: Symbol
  let allowedCharacters: CharacterGroup
  let ending1: E
  let ending2: E2

  var expression: Expression {
    ConcatenateExpressions {
      Choice {
        ConcatenateExpressions {
          "\""
          self.ending1
        }
        ConcatenateExpressions {
          self.allowedCharacters
          Ref(self.name)
        }
        ConcatenateExpressions {
          "\\"
          Ref("escape")
          Ref(self.name)
        }
      }
      ConcatenateExpressions {
        "="
        ZeroOrMore { CharacterGroup.jsonWhitespace }
        self.ending2
      }
    }
  }
}

extension CharacterGroup {
  fileprivate static let jsonWhitespace = Self(" \\n\\t")
}

private struct JSONElement: ExpressionComponent {
  var withEmbrace = false
  @ExpressionBuilder var content: () -> Expression

  var expression: Expression {
    ConcatenateExpressions {
      content()
      Ref("elements_rest")
      if self.withEmbrace {
        ZeroOrMore { CharacterGroup.jsonWhitespace }
        "]"
      }
    }
  }
}

private struct JSONMembersEnding: ExpressionComponent {
  var expression: Expression {
    GroupExpression {
      "="
      CharacterGroup(" \\n\\t,}#x5D")
    }
  }
}
