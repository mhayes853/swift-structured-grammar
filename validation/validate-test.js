import { Grammars } from "ebnf";
import GBNF from "gbnf";

try {
  const grammar = new Grammars.BNF.Parser(
    `
// A W3C comment
<start> ::= "value"
`,
  );
  console.log("fine");
} catch (e) {
  console.error(e);
}
