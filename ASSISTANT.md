# PlumWallPaper 项目约定（v2.0 - SwiftUI + Metal 重写版）

## 架构概览

- **UI 层**: SwiftUI (NavigationSplitView + TabView)，macOS 14.0+
- **渲染引擎**: Metal (VideoDecoder → ShaderGraph → MTKView → DesktopWindow)
- **数据层**: SwiftData (@Model + @Observable)
- **构建**: Xcode project (`PlumWallPaper.xcodeproj`)

## 关键路径

| 模块 | 路径 |
|------|------|
| 主应用入口 | `Sources/App/PlumWallPaperApp.swift` |
| AppDelegate（启动恢复） | `Sources/App/AppDelegate.swift` |
| 主导航 | `Sources/Views/ContentView.swift` |
| 壁纸库 UI | `Sources/Views/Library/LibraryView.swift` |
| 预览页 UI | `Sources/Views/Preview/PreviewView.swift` |
| 着色器编辑器 UI | `Sources/Views/ShaderEditor/ShaderEditorView.swift` |
| 着色器实时预览 | `Sources/Views/ShaderEditor/ShaderPreviewView.swift` |
| 设置 UI | `Sources/Views/Settings/SettingsView.swift` |
| Metal 渲染管线（@MainActor 单例） | `Sources/Engine/RenderPipeline.swift` |
| 屏幕渲染器（每屏一个） | `Sources/Engine/ScreenRenderer.swift` |
| Metal 视频解码器 | `Sources/Engine/VideoDecoder.swift` |
| ShaderGraph + Pass | `Sources/Engine/ShaderGraph.swift` / `ShaderPass.swift` |
| Metal Shaders | `Sources/Engine/Shaders.metal` |
| 桌面窗口 | `Sources/Engine/DesktopWindow.swift` |
| 粒子系统 | `Sources/Engine/ParticleSystem.swift` / `ParticleEmitter.swift` |
| SwiftData 模型 | `Sources/Storage/Models/` |
| PreferencesStore | `Sources/Storage/PreferencesStore.swift` |
| 智能暂停 | `Sources/Core/PauseStrategyManager.swift` |
| 性能监控（Metal FPS） | `Sources/Core/PerformanceMonitor.swift` |
| 轮播调度器 | `Sources/Core/SlideshowScheduler.swift` |
| 音频闪避 | `Sources/Core/AudioDuckingMonitor.swift` |
| 文件导入 | `Sources/Core/FileImporter.swift` |
| 缩略图 | `Sources/Core/ThumbnailGenerator.swift` |
| 帧率回填 | `Sources/Core/FrameRateBackfiller.swift` |
| 显示器管理 | `Sources/Core/DisplayManager.swift` / `ScreenInfo.swift` |
| 全局快捷键 | `Sources/Core/GlobalShortcutManager.swift` |
| 开机启动 | `Sources/Core/LaunchAtLoginManager.swift` |
| 启动恢复 | `Sources/Core/RestoreManager.swift` |

## 构建命令

```bash
cd PlumWallPaper
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Release build
```

## 开发约定

- 新增 Swift 源文件必须手动加入 `project.pbxproj`（PBXFileReference + PBXBuildFile + PBXGroup + Sources build phase）
- Metal Shader 修改后需要 Clean Build Folder 才能生效
- 设置变更后必须调用 `PauseStrategyManager.shared.reevaluate()` 使暂停策略立即生效
- 壁纸设置后必须写 `RestoreManager.shared.saveSession(mapping:)` 保证重启恢复
- FPS 监控基于 MTKView 的实测帧率（`ScreenRenderer.measuredFPS`）
- GPU 监控基于 IOKit `IOAccelerator` 的 `PerformanceStatistics`
- 渲染、设置、Service 层全部 `@MainActor`，跨线程通过 `Task { @MainActor in ... }`

## Phase 1 完成状态（2026-05-02）

### 已完成
- SwiftUI 完整 UI（壁纸库 + 预览 + 着色器编辑器 + 设置 + 菜单栏）
- Metal 渲染引擎（VideoDecoder + ShaderGraph + DesktopWindow + ScreenRenderer）
- 7 个基础滤镜 Pass（曝光/对比度/饱和度/色调/灰度/反转/暗角）
- GPU 粒子系统（百万级粒子 + Compute Shader）
- SwiftData 数据层（Wallpaper / Tag / ShaderPreset / Settings）
- Service 层迁移完成
  - PauseStrategyManager（电池/全屏/低电量/屏幕共享/高负载/失去焦点/睡眠前）
  - PerformanceMonitor（实际 Metal 帧率）
  - SlideshowScheduler（回调式 + RenderPipeline）
  - AudioDuckingMonitor（接入 RenderPipeline 静音 API）
  - FileImporter / ThumbnailGenerator / FrameRateBackfiller
  - DisplayManager / ScreenInfo
- 系统集成
  - GlobalShortcutManager
  - LaunchAtLoginManager
  - RestoreManager（启动时自动恢复）
- AppDelegate 启动时调用 `setupRenderers()` + `restoreSession()`

### 待完成（Phase 2+）
- 着色器编辑器 ShaderPreviewView 与 RenderPipeline 实时同步
- 高斯模糊 / 颗粒噪点 Pass
- Bloom / 色散 / 运动模糊后处理 Pass
- 轮播调度器 UI 配置
- 应用规则黑名单 UI
- 在线壁纸源
- Wallpaper Engine 兼容

---
*上次更新: 2026-05-02*
