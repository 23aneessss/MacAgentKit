// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacAgentKit",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        // Umbrella product re-exporting every module.
        .library(name: "MacAgentKit", targets: ["MacAgentKit"]),
        // Individual modules, so consumers can depend on just one.
        .library(name: "MAPermissions", targets: ["MAPermissions"]),
        .library(name: "MAAccessibility", targets: ["MAAccessibility"]),
        .library(name: "MASystemControls", targets: ["MASystemControls"]),
        .library(name: "MAShortcuts", targets: ["MAShortcuts"]),
        .library(name: "MAInput", targets: ["MAInput"]),
        .library(name: "MAApps", targets: ["MAApps"]),
    ],
    dependencies: [
        // Dev/docs only — not a runtime dependency.
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
    ],
    targets: [
        // MARK: Core
        .target(
            name: "MAAccessibility",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "MAPermissions",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "MAShortcuts",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "MAApps",
            swiftSettings: swiftSettings
        ),
        .target(
            name: "MAInput",
            dependencies: ["MAAccessibility"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "MASystemControls",
            dependencies: ["MAAccessibility", "MAShortcuts"],
            swiftSettings: swiftSettings
        ),

        // MARK: Umbrella
        .target(
            name: "MacAgentKit",
            dependencies: [
                "MAPermissions",
                "MAAccessibility",
                "MASystemControls",
                "MAShortcuts",
                "MAInput",
                "MAApps",
            ],
            swiftSettings: swiftSettings
        ),

        // MARK: Tests
        .testTarget(
            name: "MacAgentKitTests",
            dependencies: [
                "MAAccessibility",
                "MAPermissions",
                "MAShortcuts",
                "MAApps",
                "MASystemControls",
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

/// Shared Swift settings applied to every target. Swift 6 language mode with
/// complete concurrency checking — the package is written to be data-race-safe.
var swiftSettings: [SwiftSetting] {
    [
        .swiftLanguageMode(.v6)
    ]
}
