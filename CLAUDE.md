# PlumWallPaper 项目约定

## 架构概览

- **UI 层**: SwiftUI + AppKit 窗口编排
- **渲染引擎**: Metal + AVFoundation
- **数据持久化**: SwiftData
- **构建**: Xcode project (`PlumWallPaper.xcodeproj`)，macOS 14.0+
- **项目生成**: XcodeGen (`project.yml`)
- **遗留原型**: `Sources/Resources/Web/plumwallpaper.html` 仍随资源打包，但不是当前主 UI 源码

## 关键路径

| 模块 | 路径 |
|------|------|
| 应用入口 | `Sources/App/PlumWallPaperApp.swift` |
| 应用代理 | `Sources/App/AppDelegate.swift` |
| 主容器视图 | `Sources/Views/ContentView.swift` |
| 首页/探索/我的库 | `Sources/Views/Home/` `Sources/Views/Explore/` `Sources/Views/Library/` |
| 设置与实验室 | `Sources/Views/Settings/` `Sources/Views/ShaderEditor/` |
| 视图模型 | `Sources/ViewModels/` |
| 数据模型 | `Sources/Storage/Models/` |
| 渲染引擎 | `Sources/Engine/` |
| 核心服务 | `Sources/Core/` |
| 在线数据源 | `Sources/Network/` `Sources/Repositories/` `Sources/OnlineModels/` |
| 系统与下载服务 | `Sources/Services/` |
| 设计参考资源 | `Sources/Resources/Web/plumwallpaper.html` |

## 构建命令

```bash
# 修改 project.yml 后重新生成 Xcode 项目
xcodegen generate

# 构建 Debug app（推荐）
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug -derivedDataPath Build/DerivedData build

# 启动本地 Debug app
open Build/DerivedData/Build/Products/Debug/PlumWallPaper.app
```

也可以直接运行：

```bash
./run.sh
```

## 开发约定

- 使用 XcodeGen 管理项目结构，修改 `project.yml` 后运行 `xcodegen generate`
- 新增源文件放入 `Sources/` 对应子目录，XcodeGen 会自动包含
- UI 修改默认落在 `Sources/Views/` 与 `Sources/ViewModels/`，不要把 `plumwallpaper.html` 当成当前 UI 源码
- SwiftData 模型放在 `Sources/Storage/Models/`，使用 `@Model` 宏
- Metal 着色器文件放在 `Sources/Engine/Shaders.metal`
- 资源文件放在 `Sources/Resources/`
- 验证主界面时使用 Xcode / DerivedData 构建产物，不要用旧的 SwiftPM `.build` 可执行文件

## 当前仓库状态（2026-05-04）

### 已在仓库中落地

- 原生应用壳：主窗口、设置窗口、菜单栏入口、SwiftData 容器
- SwiftUI 页面：Home、Wallpaper Explore、Media Explore、My Library、Settings、Shader Editor
- SwiftData 模型与存储：`Wallpaper`、`Tag`、`ShaderPreset`、`Settings`、`WallpaperStore`、`PreferencesStore`
- Metal 引擎代码：`VideoDecoder`、`RenderPipeline`、`ScreenRenderer`、`ShaderGraph`、`ShaderPass`、`ParticleSystem`
- 核心服务：显示器管理、轮播、音频闪避、恢复、导入、缩略图、性能监控、快捷键、开机启动
- 在线内容栈：Wallhaven / 4K Wallpapers / Workshop 等数据源与下载流程

### 当前需要特别注意

- `Sources/Resources/Web/plumwallpaper.html` 是历史设计原型/参考资源，不是当前运行中的主界面
- `Sources/Core/PerformanceMonitor.swift` 当前把 `NSScreen.maximumFramesPerSecond` 作为 FPS 代理值显示，不能等同于真实渲染 FPS
- `docs/` 目录里有若干阶段性报告和计划文档，属于时间快照；原先散落在项目根目录的历史总结已收拢到 `docs/archive/`
- 做实现判断时优先以源码、README 和本文件为准

---
*上次更新: 2026-05-04*
