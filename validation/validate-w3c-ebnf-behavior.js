import { Grammars } from "ebnf";
import { readFileSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const rootDir = join(__dirname, "..");
const snapshotDir = join(
  rootDir,
  "Tests",
  "StructuredCFGTests",
  "Formatters",
  "__Snapshots__",
  "W3CEBNFSnapshotTests"
);

const behaviorCases = [
  {
    name: "unioned-grammar",
    accepts: ["pass", "letidentifier", "0", "1"],
    rejects: ["let", "identifier", "2", "other"]
  },
  {
    name: "helper-production-grammar",
    accepts: ["a", "abba"],
    rejects: ["c", "abc"]
  },
  {
    name: "concatenated-grammar",
    accepts: ["ab"],
    rejects: ["", "a", "b", "ba"]
  },
  {
    name: "reversed-grammar",
    accepts: ["cba"],
    rejects: ["abc", "cb", "cab"]
  }
];

function grammarFilePath(name) {
  return join(
    snapshotDir,
    `Representative-Grammars-Format-Canonically.${name}.ebnf`
  );
}

function loadParser(name) {
  const filePath = grammarFilePath(name);
  const content = readFileSync(filePath, "utf-8");
  const normalizedContent = content.endsWith("\n") ? content : content + "\n";
  return new Grammars.W3C.Parser(normalizedContent);
}

function matches(parser, input) {
  try {
    const ast = parser.getAST(input);
    return Boolean(ast) && ast.errors.length === 0 && ast.rest === "";
  } catch {
    return false;
  }
}

let hasErrors = false;

for (const behaviorCase of behaviorCases) {
  console.log(`Checking ${behaviorCase.name} behavior...`);
  let caseHasErrors = false;

  let parser;

  try {
    parser = loadParser(behaviorCase.name);
  } catch (error) {
    hasErrors = true;
    caseHasErrors = true;
    console.log(`  ✗ Could not load parser: ${error.message}\n`);
    continue;
  }

  for (const input of behaviorCase.accepts) {
    if (!matches(parser, input)) {
      hasErrors = true;
      caseHasErrors = true;
      console.log(`  ✗ Expected acceptance for ${JSON.stringify(input)}`);
    }
  }

  for (const input of behaviorCase.rejects) {
    if (matches(parser, input)) {
      hasErrors = true;
      caseHasErrors = true;
      console.log(`  ✗ Expected rejection for ${JSON.stringify(input)}`);
    }
  }

  if (!caseHasErrors) {
    console.log("  ✓ Behavior matches expectations\n");
  } else {
    console.log("");
  }
}

if (hasErrors) {
  console.log("W3C behavior validation FAILED");
  process.exit(1);
} else {
  console.log("All W3C behavior checks passed ✓");
}
