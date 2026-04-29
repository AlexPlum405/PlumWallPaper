# PlumWallPaper 项目约定

## 架构概览

- **UI 层**: WebView + React 单文件 (`plumwallpaper.html`)，通过 `WebBridge.swift` 与 Swift 后端通信
- **后端**: Swift (SwiftData + AVFoundation + AppKit)
- **构建**: Xcode project (`PlumWallPaper.xcodeproj`)，macOS 14.0+

## 关键路径

| 模块 | 路径 |
|------|------|
| 前端 UI（全部） | `Sources/Resources/Web/plumwallpaper.html` |
| JS↔Swift 桥接 | `Sources/Bridge/WebBridge.swift` |
| 渲染引擎 | `Sources/Core/WallpaperEngine/WallpaperEngine.swift` |
| 性能监控 | `Sources/Core/PerformanceMonitor.swift` |
| 智能暂停 | `Sources/Core/PauseStrategyManager.swift` |
| 帧率补全 | `Sources/Core/FrameRateBackfiller.swift` |
| 数据模型 | `Sources/Storage/Models/` |
| 启动恢复 | `Sources/Core/RestoreManager.swift` |

## 构建命令

```bash
cd PlumWallPaper
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
```

## 开发约定

- 新增 Swift 源文件必须手动加入 `project.pbxproj`（PBXBuildFile + PBXFileReference + group + build phase）
- 前端修改只改 `plumwallpaper.html`，不拆外部 JS 文件（WebView 用 `file://` 协议加载）
- 设置变更后必须调用 `PauseStrategyManager.shared.reevaluate()` 使暂停策略立即生效
- 壁纸设置后必须写 `RestoreManager.saveSession(mapping:)` 保证重启恢复
- FPS 监控基于 `AVPlayer.rate * nominalFrameRate`，不使用 CVDisplayLink
- GPU 监控基于 IOKit `IOAccelerator` 的 `PerformanceStatistics`

## 功能完成状态（2026-04-29）

### 已完成
- 视频/HEIC 壁纸渲染 + 多显示器 + 全景模式
- 9 参数实时滤镜（Core Image）
- 文件导入 + 重复检测 + 缩略图生成
- 启动自动恢复壁纸
- 性能监控（真实 FPS / GPU / 内存，SVG 波形图）
- FPS 上限（动态检测屏幕刷新率，支持自定义值）
- 智能暂停策略（电池/全屏/低电量/屏幕共享/高负载应用/失去焦点/睡眠前）
- 暂停原因实时提示 + 临时恢复按钮
- 应用规则黑名单
- 视频帧率自动检测 + 旧数据后台补全
- 壁纸库帧率筛选器

### 待完成
- 轮播调度器
- 色彩调节面板 UI 还原
- 壁纸库搜索与多选模式

---
*上次更新: 2026-04-29*
