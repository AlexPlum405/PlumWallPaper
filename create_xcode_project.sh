#!/bin/bash

# 创建新的 Xcode 项目
PROJECT_NAME="PlumWallPaper"
BUNDLE_ID="com.plum.wallpaper"

# 使用 xcodegen 或手动创建项目
# 由于没有 xcodegen，我们使用 swift package init 然后转换

echo "正在创建新的 Xcode 项目..."

# 创建 Package.swift
cat > Package.swift << 'PACKAGE'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PlumWallPaper",
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
PACKAGE

echo "✅ 已创建 Package.swift"

# 生成 Xcode 项目
swift package generate-xcodeproj

echo "✅ 已生成 Xcode 项目"
