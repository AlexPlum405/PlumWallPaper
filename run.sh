#!/bin/bash

# PlumWallPaper 启动脚本

cd "$(dirname "$0")"

echo "🔄 停止旧进程..."
pkill -9 PlumWallPaper 2>/dev/null
sleep 1

echo "🚀 启动 PlumWallPaper..."
.build/arm64-apple-macosx/debug/PlumWallPaper &

sleep 2

echo ""
echo "✅ 应用已启动！"
echo ""
echo "📊 进程信息："
ps aux | grep PlumWallPaper | grep -v grep | head -3
echo ""
echo "💡 提示："
echo "  - 首页会自动加载 Hero 轮播、最新壁纸、热门动态"
echo "  - 切换到其他标签页会自动加载数据"
echo "  - 如果没有数据，点击首页的'🔄 手动加载数据'按钮"
echo ""
echo "🔍 查看日志："
echo "  log stream --predicate 'process == \"PlumWallPaper\"' --level debug"
