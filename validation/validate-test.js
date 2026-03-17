import { Grammars } from "ebnf";
import GBNF from "gbnf";

try {
  const grammar = new Grammars.W3C.Parser(
    `
root ::= first - second
first ::= "a"
second ::= "b"
`,
  );
  console.log("fine");
} catch (e) {
  console.error(e);
}
