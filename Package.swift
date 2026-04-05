// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "swift-structured-grammar",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
    .macCatalyst(.v13)
  ],
  products: [
    .library(
      name: "StructuredCFG",
      targets: ["StructuredCFG"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.7.0"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"),
    .package(url: "https://github.com/mattt/swift-xgrammar", from: "0.1.0")
  ],
  targets: [
    .target(
      name: "StructuredCFG",
      dependencies: [
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay")
      ]
    ),
    .testTarget(
      name: "StructuredCFGTests",
      dependencies: [
        "StructuredCFG",
        .product(
          name: "XGrammar",
          package: "swift-xgrammar",
          condition: .when(platforms: [.iOS, .macOS, .tvOS, .visionOS, .watchOS, .linux])
        ),
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
        .product(name: "IssueReportingTestSupport", package: "xctest-dynamic-overlay"),
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
      ],
      exclude: ["__Snapshots__"]
    )
  ],
  swiftLanguageModes: [.v6]
)
