import SnapshotTesting
import StructuredEBNF

extension Snapshotting where Value == Grammar, Format == String {
  static func ebnf() -> Self {
    Self(pathExtension: "ebnf", diffing: .lines) { grammar in
      grammar.formatted()
    }
  }
}
