// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "geul",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(
            url: "https://github.com/sindresorhus/KeyboardShortcuts",
            from: "2.0.0"
        ),
    ],
    targets: [
        .executableTarget(
            name: "geul",
            dependencies: [
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ],
            path: "geul",
            exclude: ["Assets.xcassets", "geul.entitlements"],
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "geulTests",
            dependencies: ["geul"],
            path: "Tests/geulTests"
        ),
    ]
)
