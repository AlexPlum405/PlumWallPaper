# PlumWallPaper v2.0

> macOS 动态壁纸引擎 — SwiftUI + Metal 原生实现，支持视频/HEIC 壁纸、多显示器、实时着色器、GPU 粒子系统

---

## 功能

| 功能 | 状态 |
|------|------|
| 视频壁纸（MP4/MOV） | ✅ |
| HEIC 动态壁纸 | ✅ |
| 多显示器独立控制 | ✅ |
| 智能显示器检测 | ✅ |
| 文件导入 + 重复检测 | ✅ |
| 缩略图自动生成 | ✅ |
| 7 参数实时着色器 Pass | ✅ |
| GPU 粒子系统（百万级） | ✅ |
| 启动自动恢复壁纸 | ✅ |
| 壁纸库管理 + 收藏/标签 | ✅ |
| 轮播调度 | ✅ |
| 智能暂停策略（7 种条件 + 应用黑名单） | ✅ |
| 实时性能监控（Metal FPS / GPU / 内存） | ✅ |
| FPS 上限（动态检测屏幕刷新率） | ✅ |
| 视频帧率自动检测 + 库内筛选 | ✅ |
| 全局快捷键 | ✅ |
| 开机启动 | ✅ |
| 媒体播放音频闪避 | ✅ |

## 着色器 Pass

曝光 · 对比度 · 饱和度 · 色调 · 灰度 · 反转 · 暗角

## 技术栈

- SwiftUI（UI 层）
- SwiftData（@Model 持久化）
- Metal + MetalKit（渲染引擎，CVPixelBuffer 零拷贝）
- AVFoundation（视频解码 + 帧率检测）
- AppKit（桌面窗口 + NSWorkspace 监控）
- IOKit（GPU 利用率 + 电源状态）

## 系统要求

- macOS 14.0+
- Xcode 16.0+
- Apple Silicon / Intel

## 工程结构

```
PlumWallPaper/Sources/
├── App/
│   ├── PlumWallPaperApp.swift         # 入口 + SwiftData 容器
│   └── AppDelegate.swift              # 启动渲染 + 恢复会话
│
├── Engine/                            # ── Metal 渲染引擎 ──
│   ├── RenderPipeline.swift           # @MainActor 单例，管理 ScreenRenderer
│   ├── ScreenRenderer.swift           # 每屏一个 MTKViewDelegate
│   ├── DesktopWindow.swift            # NSWindow + MTKView
│   ├── VideoDecoder.swift             # AVAssetReader + CVPixelBuffer
│   ├── ShaderGraph.swift              # 串行 Pass 执行
│   ├── ShaderPass.swift               # ComputeShaderPass + 参数
│   ├── Shaders.metal                  # 滤镜 + 粒子 Metal kernel
│   ├── ParticleSystem.swift           # 粒子 ShaderPass
│   └── ParticleEmitter.swift          # 粒子发射器配置
│
├── Core/                              # ── Service 层 ──
│   ├── PauseStrategyManager.swift     # 智能暂停
│   ├── PerformanceMonitor.swift       # 实测 Metal FPS
│   ├── SlideshowScheduler.swift       # 轮播
│   ├── AudioDuckingMonitor.swift      # 音频闪避
│   ├── FileImporter.swift             # 导入
│   ├── ThumbnailGenerator.swift       # 缩略图
│   ├── FrameRateBackfiller.swift      # 帧率回填
│   ├── DisplayManager.swift           # 显示器
│   ├── ScreenInfo.swift
│   ├── GlobalShortcutManager.swift    # 全局快捷键
│   ├── LaunchAtLoginManager.swift     # 开机启动
│   └── RestoreManager.swift           # 启动恢复
│
├── ViewModels/                        # @Observable @MainActor
│   ├── LibraryViewModel.swift
│   ├── PreviewViewModel.swift
│   ├── ShaderEditorViewModel.swift
│   ├── SettingsViewModel.swift
│   └── MenuBarViewModel.swift
│
├── Views/                             # SwiftUI 层
│   ├── ContentView.swift
│   ├── Library/
│   ├── Preview/
│   ├── ShaderEditor/                  # 含 ShaderPreviewView (MTKView)
│   ├── Settings/
│   ├── MenuBar/
│   └── Components/
│
└── Storage/
    ├── Models/
    │   ├── Wallpaper.swift
    │   ├── Tag.swift
    │   ├── ShaderPreset.swift
    │   ├── Settings.swift
    │   └── Enums.swift
    └── PreferencesStore.swift
```

## 构建

```bash
cd PlumWallPaper
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
```

或在 Xcode 中打开 `PlumWallPaper/PlumWallPaper.xcodeproj`，按 Cmd+R 运行。

## 许可

MIT
