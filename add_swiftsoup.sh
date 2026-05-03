#!/bin/bash
# 自动添加 SwiftSoup 依赖的脚本

echo "🔧 正在添加 SwiftSoup 依赖..."

cd /Users/Alex/AI/project/PlumWallPaper

# 使用 xcodebuild 添加包依赖
# 注意：这需要 Xcode 13+ 支持
xcodebuild -resolvePackageDependencies -project PlumWallPaper.xcodeproj -scheme PlumWallPaper

echo "✅ 请在 Xcode 中手动添加 SwiftSoup："
echo "   1. 打开 PlumWallPaper.xcodeproj"
echo "   2. 选择项目 → PlumWallPaper target → Package Dependencies"
echo "   3. 点击 '+' 添加："
echo "      URL: https://github.com/scinfu/SwiftSoup.git"
echo "      Version: Up to Next Major Version 2.0.0"
echo ""
echo "或者运行以下命令（需要 Xcode 命令行工具）："
echo "   cd /Users/Alex/AI/project/PlumWallPaper"
echo "   swift package resolve"
