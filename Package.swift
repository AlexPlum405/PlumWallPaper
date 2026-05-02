// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PlumWallPaper",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "PlumWallPaper", targets: ["PlumWallPaper"])
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "PlumWallPaper",
            dependencies: ["SwiftSoup"],
            path: "Sources"
        )
    ]
)
