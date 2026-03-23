from __future__ import annotations

import importlib
import subprocess
import sys
from pathlib import Path


VALIDATION_DIR = Path(__file__).resolve().parent
SNAPSHOT_DIR = (
  VALIDATION_DIR.parent
  / "Tests"
  / "StructuredCFGTests"
  / "Formatters"
  / "__Snapshots__"
  / "ISOSnapshotTests"
)
PACKAGE_DIR = VALIDATION_DIR / ".python-packages"
REQUIREMENTS_PATH = VALIDATION_DIR / "requirements.txt"


def main() -> int:
  parsing = load_parse_ebnf()
  grammar_files = sorted(SNAPSHOT_DIR.glob("*.ebnf"))

  if not grammar_files:
    print("No .ebnf files found in snapshot directory", file=sys.stderr)
    return 1

  print(f"Found {len(grammar_files)} ISO/IEC grammar files to validate\n")

  has_errors = False
  for grammar_file in grammar_files:
    print(f"Validating {grammar_file.name}...")
    try:
      parsing.parse_file(grammar_file)
      print("  Valid\n")
    except parsing.ParsingError as error:
      print("  Invalid")
      print(f"    Error: {error}\n")
      has_errors = True

  if has_errors:
    print("ISO/IEC validation FAILED")
    return 1

  print("All ISO/IEC grammars are valid")
  return 0


def load_parse_ebnf():
  if str(PACKAGE_DIR) not in sys.path:
    sys.path.insert(0, str(PACKAGE_DIR))

  try:
    return importlib.import_module("parse_ebnf.parsing")
  except ModuleNotFoundError:
    PACKAGE_DIR.mkdir(parents=True, exist_ok=True)
    subprocess.run(
      [
        sys.executable,
        "-m",
        "pip",
        "install",
        "--disable-pip-version-check",
        "--quiet",
        "--target",
        str(PACKAGE_DIR),
        "-r",
        str(REQUIREMENTS_PATH),
      ],
      check=True,
    )
    importlib.invalidate_caches()
    return importlib.import_module("parse_ebnf.parsing")


if __name__ == "__main__":
  raise SystemExit(main())
