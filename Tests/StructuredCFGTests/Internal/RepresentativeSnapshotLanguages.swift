import StructuredCFG

struct RepresentativeSnapshotLanguageCase: Hashable, Sendable {
  let name: String
  let language: Language
}

enum RepresentativeSnapshotLanguageSuite {
  static let cases = [
    RepresentativeSnapshotLanguageCase(
      name: "arithmetic-grammar",
      language: Grammar(startingSymbol: "expression") {
        Rule("expression") {
          Ref("term")
          ZeroOrMore {
            ChoiceOf {
              "+"
              "-"
            }
            Ref("term")
          }
        }

        Rule("term") {
          Ref("factor")
          ZeroOrMore {
            ChoiceOf {
              "*"
              "/"
            }
            Ref("factor")
          }
        }

        Rule("factor") {
          ChoiceOf {
            Ref("number")
            GroupExpression {
              "("
              Ref("expression")
              ")"
            }
          }
        }

        Rule("number") {
          OneOrMore {
            Ref("digit")
          }
        }

        Rule("digit") {
          ChoiceOf {
            "0"
            "1"
            "2"
          }
        }
      }
      .language
    ),
    RepresentativeSnapshotLanguageCase(
      name: "unioned-grammar",
      language: Union {
        Grammar(startingSymbol: "expression") {
          Rule("expression") {
            Ref("number")
          }

          Rule("number") {
            OneOrMore {
              Ref("digit")
            }
          }

          Rule("digit") {
            ChoiceOf {
              "0"
              "1"
            }
          }
        }

        Grammar(startingSymbol: "statement") {
          Rule("statement") {
            ChoiceOf {
              "pass"
              ConcatenateExpressions {
                "let"
                Ref("identifier")
              }
            }
          }

          Rule("identifier") {
            "identifier"
          }
        }
      }
      .language
    ),
    RepresentativeSnapshotLanguageCase(
      name: "namespaced-grammar",
      language: Grammar(startingSymbol: .root) {
        Rule(.root) {
          ChoiceOf {
            Ref("ga-expression")
            Ref("gb-expression")
          }
        }

        Rule("ga-expression") {
          Ref("ga-term")
        }

        Rule("ga-term") {
          "left"
        }

        Rule("gb-expression") {
          Ref("gb-term")
        }

        Rule("gb-term") {
          "right"
        }
      }
      .language
    ),
    RepresentativeSnapshotLanguageCase(
      name: "helper-production-grammar",
      language: Star {
        Grammar(startingSymbol: "token") {
          Rule("token") {
            ChoiceOf {
              "a"
              "b"
            }
          }
        }
      }
      .language
    ),
    RepresentativeSnapshotLanguageCase(
      name: "concatenated-grammar",
      language: ConcatenateLanguages {
        Grammar(startingSymbol: "prefix") {
          Rule("prefix") {
            "a"
          }
        }

        Grammar(startingSymbol: "suffix") {
          Rule("suffix") {
            "b"
          }
        }
      }
      .language
    ),
    RepresentativeSnapshotLanguageCase(
      name: "reversed-grammar",
      language: Reverse {
        Grammar(startingSymbol: "expression") {
          Rule("expression") {
            ConcatenateExpressions {
              "a"
              Ref("term")
            }
          }

          Rule("term") {
            ConcatenateExpressions {
              "b"
              "c"
            }
          }
        }
      }
      .language
    ),
    RepresentativeSnapshotLanguageCase(
      name: "comprehensive-grammar",
      language: Grammar(startingSymbol: "document") {
        Rule("document") {
          Ref("header")
          OneOrMore {
            Ref("assignment")
          }
          OptionalExpression {
            Ref("footer")
          }
        }

        Rule("header") {
          "BEGIN"
        }

        Rule("assignment") {
          Ref("identifier")
          "="
          ChoiceOf {
            Ref("literal")
            Ref("tuple")
            "computed"
          }
        }

        Rule("tuple") {
          "("
          Ref("literal")
          ZeroOrMore {
            GroupExpression {
              ","
              Ref("literal")
            }
          }
          ")"
        }

        Rule("literal") {
          ChoiceOf {
            Ref("number")
            Ref("ga-qualified")
            "quoted"
          }
        }

        Rule("number") {
          OneOrMore {
            Ref("digit")
          }
        }

        Rule("digit") {
          ChoiceOf {
            "0"
            "1"
            "2"
          }
        }

        Rule("identifier") {
          "identifier"
        }

        Rule("footer") {
          "END"
        }

        Rule("padding") {
          Epsilon()
        }

        Rule("ga-qualified") {
          "qualified"
        }
      }
      .language
    ),
    RepresentativeSnapshotLanguageCase(
      name: "hex-terminal-grammar",
      language: Grammar(startingSymbol: "hexOnly") {
        Rule("hexOnly") {
          Terminal(hex: ["A".unicodeScalars.first!, "\t".unicodeScalars.first!])
        }
        Rule("mixed") {
          Terminal(characters: [.hex("a".unicodeScalars.first!), .character("a")])
        }
        Rule("surrounded") {
          Terminal(characters: [
            .character("["),
            .hex("A".unicodeScalars.first!),
            .character("]")
          ])
        }
      }
      .language
    ),
    RepresentativeSnapshotLanguageCase(
      name: "json-grammar",
      language: Language { JSON() }
    ),
    RepresentativeSnapshotLanguageCase(
      name: "character-group-grammar",
      language: Grammar(startingSymbol: "identifier") {
        Rule("identifier") {
          CharacterGroup("a-zA-Z_")
          ZeroOrMore {
            CharacterGroup("a-zA-Z0-9_")
          }
        }
        Rule("digit") {
          CharacterGroup("\\d")
        }
        Rule("word") {
          CharacterGroup("\\w")
        }
        Rule("whitespace") {
          CharacterGroup("\\s")
        }
        Rule("hex-digit") {
          CharacterGroup("0-9a-fA-F")
        }
        Rule("escaped") {
          CharacterGroup("\\n\\r\\t")
        }
      }
      .language
    ),
    RepresentativeSnapshotLanguageCase(
      name: "range-grammar",
      language: Grammar(startingSymbol: "password") {
        Rule("password") {
          Repeat(2..., Terminal("x"))
        }
        Rule("code") {
          Repeat(4, Terminal("0"))
        }
        Rule("upto5") {
          Repeat(...5, Terminal("a"))
        }
        Rule("bounded") {
          Repeat(1...3, Terminal("b"))
        }
      }
      .language
    ),
    RepresentativeSnapshotLanguageCase(
      name: "hex-character-group-grammar",
      language: Grammar(startingSymbol: "hex-char") {
        Rule("hex-char") {
          CharacterGroup("#x41")
        }
        Rule("hex-range") {
          CharacterGroup("#x30-#x39")
        }
        Rule("hex-escape") {
          CharacterGroup("\\x41")
        }
        Rule("mixed-hex") {
          CharacterGroup("a-z#x41")
        }
      }
      .language
    )
  ]

  static func snapshotCase(named name: String) -> RepresentativeSnapshotLanguageCase {
    self.cases.first(where: { $0.name == name })!
  }

  static func replacingJSONLanguage(with language: Language) -> [RepresentativeSnapshotLanguageCase]
  {
    self.cases.map { snapshotCase in
      guard snapshotCase.name == "json-grammar" else {
        return snapshotCase
      }
      return RepresentativeSnapshotLanguageCase(
        name: snapshotCase.name,
        language: language
      )
    }
  }
}
