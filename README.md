# Swift Structured EBNF

Type-Safe EBNF grammar creation.

## Overview

```swift
let grammar = Grammar(startingIdentifier: "num") {
    Production("num") {
        OptionalExpression {
            Choice {
                "-"
                "+"
            }
        }
        ZeroOrMore {
            Choice {
                "0"
                "1"
                "2"
                "3"
                "4"
                "5"
                "6"
                "7"
                "8"
                "9"
            }
        }
    }
    Production("literal case") {
        "literal value"
    }
}

let extended = Language {
    ConcatenateLanguages {
        grammar
        grammar
        KleeneStar {
            grammar
        }
    }
}
```
