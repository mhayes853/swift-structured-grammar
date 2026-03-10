# Swift Structured EBNF

Type-Safe EBNF grammar creation.

## Overview

```swift
let grammar = Grammar {
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
    Production("special case") {
        Special("this is a special sequence of some kind")
    }
}

let extended = Language {
    Concatenate {
        grammar
        grammar
        KleeneStar {
            grammar
        }
    }
}
```
