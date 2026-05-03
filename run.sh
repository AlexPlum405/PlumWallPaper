#!/bin/bash
set -euo pipefail

# PlumWallPaper 启动脚本
#
# Always build and launch the Xcode app bundle. Launching the SwiftPM
# .build executable can leave the app on a stale UI where hero actions such as
# favorite/download disappear.

cd "$(dirname "$0")"

APP_PATH="Build/DerivedData/Build/Products/Debug/PlumWallPaper.app"

echo "🔨 构建 Xcode Debug app..."
xcodebuild \
  -project PlumWallPaper.xcodeproj \
  -scheme PlumWallPaper \
  -configuration Debug \
  -derivedDataPath Build/DerivedData \
  build

echo "🔄 停止旧进程..."
pkill -x PlumWallPaper 2>/dev/null || true
sleep 1

echo "🚀 启动 PlumWallPaper..."
open "$APP_PATH"

sleep 2

echo ""
echo "✅ 应用已启动！"
echo ""
echo "📊 进程信息："
pgrep -fl PlumWallPaper || true
echo ""
echo "💡 提示："
echo "  - 首页会自动加载 Hero 轮播、最新壁纸、热门动态"
echo "  - Hero 收藏/下载按钮应出现在“设为壁纸”按钮右侧"
echo "  - 如果按钮缺失，先确认进程路径是否来自 Build/DerivedData"
echo ""
echo "🔍 查看日志："
echo "  log stream --predicate 'process == \"PlumWallPaper\"' --level debug"
