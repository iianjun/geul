// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "geul",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "geul",
            path: "geul"
        ),
    ]
)
