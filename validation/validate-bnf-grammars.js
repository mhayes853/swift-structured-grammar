import { Grammars } from "ebnf";
import { readFileSync, readdirSync } from "fs";
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
  "BNFSnapshotTests"
);

function getBnfFiles(dir) {
  return readdirSync(dir)
    .filter((file) => file.endsWith(".bnf"))
    .map((file) => join(dir, file));
}

function validateGrammar(filePath) {
  const content = readFileSync(filePath, "utf-8");
  const normalizedContent = normalizeBNF(content);

  try {
    new Grammars.BNF.Parser(normalizedContent);
    return { valid: true, error: null };
  } catch (error) {
    return { valid: false, error: error.message };
  }
}

function normalizeBNF(content) {
  const withoutComments = content
    .split("\n")
    .filter((line) => {
      const trimmed = line.trimStart();
      return !trimmed.startsWith("/*") && !trimmed.startsWith("(*") && !trimmed.startsWith("//");
    })
    .join("\n");
  return withoutComments.endsWith("\n") ? withoutComments : withoutComments + "\n";
}

const files = getBnfFiles(snapshotDir);

if (files.length === 0) {
  console.error("No .bnf files found in snapshot directory");
  process.exit(1);
}

console.log(`Found ${files.length} BNF grammar files to validate\n`);

let hasErrors = false;

for (const file of files) {
  const fileName = file.split("/").pop();

  console.log(`Validating ${fileName}...`);

  const result = validateGrammar(file);

  if (result.valid) {
    console.log("  Valid\n");
  } else {
    console.log("  Invalid");
    console.log(`    Error: ${result.error}\n`);
    hasErrors = true;
  }
}

if (hasErrors) {
  console.log("BNF validation FAILED");
  process.exit(1);
} else {
  console.log("All BNF grammars are valid");
  process.exit(0);
}
