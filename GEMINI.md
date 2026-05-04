# PlumWallPaper Gemini 协作约束

先看项目根目录的 `CLAUDE.md` 和 `README.md`，这里只保留命令模板和安全边界。

## 常用命令模板

### 1. 构建项目 (Build)
```bash
xcodebuild -project /Users/Alex/AI/project/PlumWallPaper/PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug -derivedDataPath /Users/Alex/AI/project/PlumWallPaper/Build/DerivedData build
```

### 2. 重启应用 (Restart)
```bash
pkill -x PlumWallPaper 2>/dev/null || true
sleep 0.8
open -n /Users/Alex/AI/project/PlumWallPaper/Build/DerivedData/Build/Products/Debug/PlumWallPaper.app
sleep 5
osascript -e 'tell application "PlumWallPaper" to activate' 2>/dev/null || true
pgrep -fl 'PlumWallPaper' || true
```

> 注意：不要用 SwiftPM `.build/.../PlumWallPaper` 路径验证主 UI；以 `Build/DerivedData` 的 `.app` 为准。

## 严格代码安全原则
- **核心原则**：“如果我没明确让你新增、修改、删除代码，你就不许修改任何代码。”
- **询问 (Inquiries)**：当用户请求分析、研究或建议时，严禁使用任何修改工具（`write_file`、`replace`、`run_shell_command` 修改态等）。仅限读取代码并汇报发现。
- **指令 (Directives)**：仅在收到明确的操作指令（如“修复”、“实现”、“执行”、“新增”、“修改”、“删除”）时，才允许修改代码。
- **发现 Bug**：在非指令模式下发现 Bug 时，必须先汇报并征求用户意见，不得擅自修复。
