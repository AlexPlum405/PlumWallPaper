# PlumWallPaper Codex 项目约束

先看项目根目录的 `CLAUDE.md` 和 `README.md`，这里仅保留高频红线。

## 当前主线
- 当前应用主线是 **SwiftUI + AppKit + Metal**。
- UI 修改默认落在 `Sources/Views/` 与 `Sources/ViewModels/`。
- `Sources/Resources/Web/plumwallpaper.html` 只是历史原型资源，不是当前主界面源码。

## 构建与运行
- 验证主界面时，使用 Xcode / DerivedData 的 app bundle。
- 推荐命令：
  ```bash
  xcodebuild -project /Users/Alex/AI/project/PlumWallPaper/PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug -derivedDataPath /Users/Alex/AI/project/PlumWallPaper/Build/DerivedData build
  open /Users/Alex/AI/project/PlumWallPaper/Build/DerivedData/Build/Products/Debug/PlumWallPaper.app
  ```
- 不要用旧的 SwiftPM `.build/.../PlumWallPaper` 可执行文件判断主 UI 是否正确。

## 文档优先级
- 当前事实优先看：源码 > `CLAUDE.md` > `README.md`
- 历史总结和阶段性战报已归档到 `docs/archive/`
- `docs/phase1-*`、`docs/superpowers/plans/*` 属于时间快照，不要直接当成当前状态

## 协作边界
- 未被明确要求时，不要因为看到历史文档里的待办或旧建议就主动改代码。
- 发现文档与代码冲突时，以当前源码为准，并优先更新主文档而不是继续复制旧说法。
