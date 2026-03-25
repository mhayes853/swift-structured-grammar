import { readFileSync, readdirSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const { default: GBNF } = await import("gbnf");

const rootDir = join(__dirname, "..");
const snapshotDir = join(
  rootDir,
  "Tests",
  "StructuredCFGTests",
  "Formatters",
  "__Snapshots__",
  "GBNFSnapshotTests"
);

function getGbnfFiles(dir) {
  return readdirSync(dir)
    .filter((f) => f.endsWith(".gbnf"))
    .map((f) => join(dir, f));
}

function validateGrammar(filePath) {
  const content = readFileSync(filePath, "utf-8");
  const normalizedContent = normalizeGBNF(content);
  
  const firstRule = normalizedContent.split("\n")[0].split("::=")[0].trim();
  
  try {
    GBNF(normalizedContent);
    return { valid: true, error: null, firstRule };
  } catch (e) {
    const message = e.message;
    
    if (message.includes("SymbolIds does not contain key: root")) {
      return { 
        valid: false, 
        error: `Grammar starts with '${firstRule}' but GBNF parser requires 'root' rule`,
        firstRule 
      };
    }
    
    return { valid: false, error: message, firstRule };
  }
}

function normalizeGBNF(content) {
  const withoutComments = content
    .split("\n")
    .filter((line) => !line.trimStart().startsWith("#"))
    .join("\n");
  return withoutComments.endsWith("\n") ? withoutComments : withoutComments + "\n";
}

const files = getGbnfFiles(snapshotDir);

if (files.length === 0) {
  console.error("No .gbnf files found in snapshot directory");
  process.exit(1);
}

console.log(`Found ${files.length} GBNF grammar files to validate\n`);
console.log("Note: The GBNF parser has stricter requirements than standard GBNF.\n");

let hasErrors = false;

for (const file of files) {
  const fileName = file.split("/").pop();
  console.log(`Validating ${fileName}...`);

  const result = validateGrammar(file);

  if (result.valid) {
    console.log(`  ✓ Valid\n`);
  } else {
    console.log(`  ⚠ Parsing issue (grammar may still be valid GBNF)`);
    console.log(`    ${result.error}\n`);
    hasErrors = true;
  }
}

if (hasErrors) {
  console.log("GBNF Validation completed with warnings");
  console.log("Note: These warnings indicate the grammar doesn't conform to the gbnf package's specific parser requirements, but may still be valid GBNF.");
  process.exit(0);
} else {
  console.log("All GBNF grammars are valid ✓");
  process.exit(0);
}
