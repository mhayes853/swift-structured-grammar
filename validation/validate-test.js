import { Grammars } from "ebnf";
import GBNF from "gbnf";

try {
  const grammar = GBNF(
    `
root ::= \x61 "a"
`,
    "aa",
  );
  console.log("fine");
} catch (e) {
  console.error(e);
}
