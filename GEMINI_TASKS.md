# PlumWallPaper 任务清单与诊断记录

## 发现与诊断记录
### [Bug] 动态壁纸铺不满全屏 (2026-05-02)
- **现象**: 用户反馈设置动态壁纸后，壁纸无法完全铺满屏幕，四周会出现缝隙（留出边距），从而露出系统原生桌面壁纸。
- **根因分析**:
  1. `DesktopWindow` 当前将 `NSWindow.level` 设置为 `-1`。
  2. 在 macOS Sonoma (14.0+) 中，默认开启了“点击墙纸显示桌面”功能（或如果用户开启了台前调度 Stage Manager）。
  3. 当窗口层级为普通应用层级（包含 `-1`）时，系统为了“显示桌面”，会将这些普通窗口缩小并添加边缘间距。这导致了壁纸周围出现未铺满的黑边/漏出底图的情况。
  4. `DesktopWindow` 中的注释提到 `kCGDesktopIconWindow 级别不可见`，这通常是因为在真正的桌面层级下，如果没有配合正确的 `collectionBehavior` 和 `isOpaque = true` 设置，窗口可能会被系统的其他图层遮挡或无法渲染。参考项目中 `WaifuX` 引擎的实现，通过正确的组合（使用 `kCGDesktopWindowLevel` 并设置 `.fullScreenAuxiliary`）可以完美解决。
- **修复方案**:
  修改 `Sources/Engine/DesktopWindow.swift` 的初始化逻辑：
  - 将窗口 `level` 从 `-1` 改为 `Int(CGWindowLevelForKey(.desktopWindow))`。
  - 将 `collectionBehavior` 增加 `.fullScreenAuxiliary`。
  - 设置 `isOpaque = true`。

## 待办任务清单
- [x] 修复动态壁纸无法铺满全屏的 Bug（已修复）。