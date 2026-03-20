import { Grammars } from "ebnf";
import GBNF from "gbnf";

try {
  const grammar = GBNF(
    `
root ::= "\\u0061"
`,
  );
  grammar.add("a");
  console.log("fine");
} catch (e) {
  console.error(e);
}
