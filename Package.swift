// swift-tools-version: 5.9
import PackageDescription

// WorthItKit: the pure-Swift, offline core (models, parsing, classification,
// analyzers, scoring). Foundation-only so it builds and tests on any platform
// without Xcode. The iOS app/extension targets layer SwiftSoup on top via the
// XcodeGen project (see project.yml); the kit itself has zero dependencies.
let package = Package(
    name: "WorthItKit",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "WorthItKit", targets: ["WorthItKit"])
    ],
    targets: [
        .target(name: "WorthItKit"),
        .testTarget(
            name: "WorthItKitTests",
            dependencies: ["WorthItKit"],
            resources: [.copy("Fixtures")]
        )
    ]
)
