import SnapshotTesting
import StructuredCFG

extension Snapshotting where Value == Grammar, Format == String {
  static func ebnf(formatter: Grammar.W3CEBNFFormatter = .w3cEbnf) -> Self {
    Self(pathExtension: "ebnf", diffing: .lines) { grammar in
      try! grammar.formatted(with: formatter)
    }
  }

  static func wirthEbnf() -> Self {
    Self(pathExtension: "ebnf", diffing: .lines) { grammar in
      try! grammar.formatted(with: .wirthEbnf)
    }
  }

  static func gbnf() -> Self {
    Self(pathExtension: "gbnf", diffing: .lines) { grammar in
      try! grammar.formatted(with: .gbnf)
    }
  }
}
