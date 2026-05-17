// swift-tools-version: 5.9
import PackageDescription

// HypeCheckKit: the pure-Swift, offline core (models, parsing, classification,
// analyzers, scoring). Foundation-only so it builds and tests on any platform
// without Xcode. The iOS app/extension targets layer SwiftSoup on top via the
// XcodeGen project (see project.yml); the kit itself has zero dependencies.
let package = Package(
    name: "HypeCheckKit",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "HypeCheckKit", targets: ["HypeCheckKit"])
    ],
    targets: [
        .target(name: "HypeCheckKit"),
        .testTarget(
            name: "HypeCheckKitTests",
            dependencies: ["HypeCheckKit"],
            resources: [.copy("Fixtures")]
        )
    ]
)
