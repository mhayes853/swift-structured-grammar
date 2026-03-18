import SnapshotTesting
import StructuredCFG

extension Snapshotting where Value == Grammar, Format == String {
  static func bnf() -> Self {
    Self(pathExtension: "bnf", diffing: .lines) { grammar in
      try! grammar.formatted(with: .bnf)
    }
  }

  static func ebnf(formatter: Grammar.W3CEBNFFormatter = .w3cEbnf) -> Self {
    Self(pathExtension: "ebnf", diffing: .lines) { grammar in
      try! grammar.formatted(with: formatter)
    }
  }

  static func isoEbnf(formatter: Grammar.ISOEBNFFormatter = .isoEbnf) -> Self {
    Self(pathExtension: "ebnf", diffing: .lines) { grammar in
      try! grammar.formatted(with: formatter)
    }
  }

  static func gbnf() -> Self {
    Self(pathExtension: "gbnf", diffing: .lines) { grammar in
      try! grammar.formatted(with: .gbnf)
    }
  }
}
