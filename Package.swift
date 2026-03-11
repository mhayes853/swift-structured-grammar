// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "swift-structured-ebnf",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
    .macCatalyst(.v13)
  ],
  products: [
    .library(
      name: "StructuredEBNF",
      targets: ["StructuredEBNF"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.0"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"),
    .package(url: "https://github.com/mattt/swift-xgrammar", from: "0.1.0")
  ],
  targets: [
    .target(name: "StructuredEBNF"),
    .testTarget(
      name: "StructuredEBNFTests",
      dependencies: [
        "StructuredEBNF",
        .product(name: "XGrammar", package: "swift-xgrammar"),
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
      ],
      exclude: ["__Snapshots__"]
    )
  ],
  swiftLanguageModes: [.v6]
)
