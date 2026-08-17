// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyJournalFoundation",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "JournalDomain", targets: ["JournalDomain"]),
        .library(name: "JournalPersistence", targets: ["JournalPersistence"]),
        .library(name: "JournalMedia", targets: ["JournalMedia"]),
        .library(name: "JournalFeatures", targets: ["JournalFeatures"])
    ],
    targets: [
        .target(name: "JournalDomain"),
        .target(name: "JournalPersistence", dependencies: ["JournalDomain", "JournalMedia"]),
        .target(name: "JournalMedia", dependencies: ["JournalDomain"]),
        .target(name: "JournalFeatures", dependencies: ["JournalDomain", "JournalPersistence", "JournalMedia"]),
        .testTarget(name: "JournalDomainTests", dependencies: ["JournalDomain"]),
        .testTarget(name: "JournalPersistenceTests", dependencies: ["JournalPersistence", "JournalMedia"])
    ]
)
