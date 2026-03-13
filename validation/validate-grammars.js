const { Grammars } = require("ebnf");
const { readFileSync, readdirSync } = require("fs");
const { join } = require("path");

const rootDir = join(__dirname, "..");
const snapshotDir = join(
  rootDir,
  "Tests",
  "StructuredCFGTests",
  "Formatters",
  "__Snapshots__",
  "LanguageSnapshotTests"
);

function getEbnfFiles(dir) {
  return readdirSync(dir)
    .filter((f) => f.endsWith(".ebnf"))
    .map((f) => join(dir, f));
}

function validateGrammar(filePath) {
  const content = readFileSync(filePath, "utf-8");
  try {
    const normalizedContent = content.endsWith("\n") ? content : content + "\n";
    new Grammars.W3C.Parser(normalizedContent);
    return { valid: true, error: null };
  } catch (e) {
    return { valid: false, error: e.message };
  }
}

const files = getEbnfFiles(snapshotDir);

if (files.length === 0) {
  console.error("No .ebnf files found in snapshot directory");
  process.exit(1);
}

console.log(`Found ${files.length} grammar files to validate\n`);

let hasErrors = false;

for (const file of files) {
  const fileName = file.split("/").pop();
  console.log(`Validating ${fileName}...`);

  const result = validateGrammar(file);

  if (result.valid) {
    console.log(`  ✓ Valid\n`);
  } else {
    console.log(`  ✗ Invalid`);
    console.log(`    Error: ${result.error}\n`);
    hasErrors = true;
  }
}

if (hasErrors) {
  console.log("Validation FAILED");
  process.exit(1);
} else {
  console.log("All grammars are valid ✓");
  process.exit(0);
}
