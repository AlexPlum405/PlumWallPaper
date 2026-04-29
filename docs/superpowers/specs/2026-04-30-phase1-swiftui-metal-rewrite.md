# Phase 1：SwiftUI + Metal 全量重写 设计文档

> **版本**: v1.0
> **日期**: 2026-04-30
> **范围**: 核心架构重构 — Metal 渲染引擎 + 粒子系统 + 着色器编辑器 + SwiftUI 完整 UI

## 目标

将 PlumWallPaper 从 WebView+React+AVPlayerLayer 架构全量重写为 SwiftUI+Metal 架构，实现：
- Metal GPU 渲染管线（零拷贝视频解码 → Compute Shader 滤镜/粒子/后处理）
- 百万级 GPU 粒子系统
- 统一着色器编辑器（参数面板 + 实时预览）
- SwiftUI 原生 UI（功能对等现有版本 + 新增着色器编辑器）
- 全新 SwiftData 模型（不兼容旧版）

## 整体架构

```
┌─────────────────────────────────────────────────────┐
│                  App Layer (SwiftUI)                 │
│  MainWindow ─┬─ LibraryView (壁纸库)                │
│              ├─ PreviewView (预览)                   │
│              ├─ ShaderEditorView (着色器编辑器)      │
│              ├─ SettingsView (设置)                  │
│              └─ MenuBarExtra (菜单栏)               │
├─────────────────────────────────────────────────────┤
│              ViewModel Layer (ObservableObject)      │
│  LibraryVM · PreviewVM · ShaderEditorVM · SettingsVM│
├─────────────────────────────────────────────────────┤
│              Engine Layer (Metal + AVFoundation)     │
│  RenderPipeline → ScreenRenderer → ShaderGraph      │
│  VideoDecoder · ParticleSystem · ShaderPass          │
├─────────────────────────────────────────────────────┤
│              Service Layer (可复用后端)              │
│  PauseStrategyManager · PerformanceMonitor          │
│  SlideshowScheduler · AudioDuckingMonitor           │
│  DisplayManager · FileImporter · RestoreManager     │
├─────────────────────────────────────────────────────┤
│              Storage Layer (SwiftData)               │
│  Wallpaper · Tag · ShaderPreset · Settings          │
├─────────────────────────────────────────────────────┤
│              System Layer (AppKit + IOKit)           │
│  DesktopWindow (NSWindow + MTKView)                 │
│  GlobalShortcuts · LaunchAtLogin · MenuBar          │
└─────────────────────────────────────────────────────┘
```

依赖规则（单向）：Views → ViewModels → Engine + Core + Storage → System

## Metal 渲染引擎

### 渲染管线

```
视频文件 (MP4/MOV/HEIC)
  ↓ VideoToolbox 硬件解码
CVPixelBuffer
  ↓ CVMetalTextureCache.createTexture() (零拷贝)
MTLTexture
  ↓ ShaderGraph.execute()
  ├─ Pass 1..N: 滤镜 (Compute Shader)
  │   曝光/对比度/饱和度/色调/模糊/颗粒/暗角/灰度/反转
  ├─ Pass N+1: 粒子系统 (Compute Shader)
  │   发射器/重力/生命周期/颜色渐变/碰撞/力场
  └─ Pass N+2: 后处理 (Compute Shader)
      Bloom/色散/运动模糊/景深
  ↓
MTLTexture (最终输出)
  ↓ MTKView.draw()
桌面窗口
```

全程 GPU，CPU 只负责调度。

### 核心类

**RenderPipeline**（@MainActor 单例）
- 维护 `[String: ScreenRenderer]` 字典（key = screenId）
- `setWallpaper(url:screen:shaderPreset:)` — 设置壁纸到指定屏幕
- `updateShaderPreset(_:screen:)` — 实时更新着色器参数
- `pause(screen:)` / `resume(screen:)` — 暂停/恢复
- `getPerformanceMetrics()` — 返回 FPS/GPU/内存

**ScreenRenderer**（每屏一个实例）
- `videoDecoder: VideoDecoder` — VideoToolbox 解码器
- `textureCache: CVMetalTextureCache` — 零拷贝纹理缓存
- `shaderGraph: ShaderGraph` — 着色器管线
- `mtkView: MTKView` — Metal 视图
- `desktopWindow: NSWindow` — 桌面窗口（level = desktopIconWindow - 1, canJoinAllSpaces）
- `func render(frame: CVPixelBuffer)` — 每帧渲染入口

**VideoDecoder**
- VideoToolbox `VTDecompressionSession` 硬件解码
- 异步解码，通过回调输出 `CVPixelBuffer`
- 支持 `AVAsset` 读取（兼容 AVFoundation 的文件格式支持）
- 循环模式：解码到末尾后 seek 回起点
- 单次模式：解码到末尾后停止

**ShaderGraph**
- `passes: [ShaderPass]` — 有序 Pass 数组
- `func execute(input: MTLTexture, commandBuffer: MTLCommandBuffer) -> MTLTexture`
- `func addPass(_:)` / `removePass(_:)` / `reorderPass(from:to:)`
- `func updateParameter(passId:key:value:)` — 实时调参
- 每个 Pass 的输出是下一个 Pass 的输入（链式）

**ShaderPass**（协议）
- `var id: UUID`
- `var name: String`
- `var type: ShaderPassType` — .filter / .particle / .postprocess
- `var enabled: Bool`
- `var parameters: [ShaderParameter]`
- `func execute(input: MTLTexture, commandBuffer: MTLCommandBuffer) -> MTLTexture`

### 粒子系统

**ParticleSystem**（实现 ShaderPass 协议）
- `emitters: [ParticleEmitter]` — 发射器数组
- `particleBuffer: MTLBuffer` — GPU 粒子缓冲区（预分配百万级）
- `aliveCount: Int` — 当前存活粒子数
- `computePipeline: MTLComputePipelineState` — 粒子更新 kernel
- `renderPipeline: MTLRenderPipelineState` — 粒子渲染 kernel
- `func update(deltaTime: Float, commandBuffer: MTLCommandBuffer)` — GPU 更新粒子位置/速度/生命
- `func execute(input: MTLTexture, commandBuffer: MTLCommandBuffer) -> MTLTexture` — 渲染粒子叠加到输入纹理

**ParticleEmitter**
- `position: SIMD2<Float>` — 发射位置（归一化 0-1）
- `rate: Float` — 发射速率（粒子/秒）
- `lifetime: ClosedRange<Float>` — 生命周期范围（秒）
- `velocity: SIMD2<Float>` — 初速度
- `velocityVariance: SIMD2<Float>` — 速度随机偏差
- `gravity: SIMD2<Float>` — 重力加速度
- `colorStart: SIMD4<Float>` / `colorEnd: SIMD4<Float>` — 颜色渐变
- `sizeStart: Float` / `sizeEnd: Float` — 大小渐变
- `texture: MTLTexture?` — 粒子纹理（nil = 圆形）

**GPU 粒子结构体**（Metal Shader 中）
```metal
struct Particle {
    float2 position;
    float2 velocity;
    float4 color;
    float size;
    float lifetime;
    float age;
    uint alive;
};
```

### 性能优化

1. **零拷贝纹理映射**：CVMetalTextureCache 直接映射 VideoToolbox 输出
2. **Compute Shader 合并**：相邻滤镜 Pass 合并为单个 kernel 减少 dispatch
3. **粒子缓冲区复用**：预分配固定大小，死亡粒子通过 atomic counter 回收
4. **Triple Buffering**：3 个 commandBuffer 轮转，解码和渲染流水线化
5. **FPS 限制**：`MTKView.preferredFramesPerSecond` 控制刷新率
6. **按需渲染**：静态壁纸（HEIC/图片）只渲染一次，除非着色器参数变化

## SwiftUI UI 架构

### 窗口结构

```
PlumWallPaperApp (@main)
  ├─ MainWindow (NSWindow, 自定义红绿灯)
  │   └─ ContentView (NavigationSplitView)
  │       ├─ Sidebar: 壁纸库 / 着色器编辑器 / 设置
  │       └─ Detail: LibraryView / ShaderEditorView / SettingsView
  ├─ PreviewWindow (独立窗口)
  └─ MenuBarExtra (菜单栏)
```

### 页面清单

| 页面 | 功能 | 对应现有功能 |
|------|------|-------------|
| LibraryView | 壁纸网格、标签筛选、帧率筛选、搜索、多选、拖拽导入、收藏 | 壁纸库页面 |
| PreviewView | 壁纸预览、进度条、音量控制、壁纸信息、设置到桌面 | 预览页 |
| ShaderEditorView | Pass 列表 + 参数面板 + MTKView 实时预览 | 色彩调节页（大幅增强） |
| SettingsView | 播放/音频/性能/暂停策略/显示/外观/资源库/快捷键 | 设置页 |
| MenuBarExtra | 当前壁纸缩略图、播放/暂停、上下一张、音量 | 菜单栏 |

### 着色器编辑器布局

```
┌──────────────────────────────────────────────────────┐
│ 着色器编辑器                              [保存预设] │
├──────────────────┬───────────────────────────────────┤
│ Pass 列表        │                                   │
│ ☑ 曝光调整       │                                   │
│ ☑ 对比度         │                                   │
│ ☑ 饱和度         │      MTKView 实时预览             │
│ ☑ 色调旋转       │      (当前壁纸 + 所有 Pass 效果)  │
│ ☐ 高斯模糊       │                                   │
│ ☐ 颗粒噪点       │                                   │
│ ☐ 暗角           │                                   │
│ ☐ 灰度           │                                   │
│ ☐ 反转           │                                   │
│ ─────────────────│                                   │
│ ☑ 粒子发射器     │                                   │
│ ☐ Bloom 辉光     │                                   │
│ ☐ 色散           │                                   │
│ ☐ 运动模糊       │                                   │
│ [+ 添加 Pass]    │                                   │
│ ─────────────────│                                   │
│ 参数面板(选中Pass)│                                   │
│ 发射速率 ━━━━━━  │                                   │
│ 生命周期 ━━━━━━  │                                   │
│ 重力     ━━━━━━  │                                   │
│ 起始颜色 🔴      │                                   │
│ 结束颜色 🟡      │                                   │
└──────────────────┴───────────────────────────────────┘
```

原色彩调节页的 9 个滤镜参数现在是 9 个独立 Pass，用户可自由启用/禁用/排序，并新增粒子和后处理 Pass。

### ViewModel 层

| ViewModel | 职责 |
|-----------|------|
| LibraryViewModel | 壁纸 CRUD、筛选排序、导入、多选、标签管理 |
| PreviewViewModel | 播放控制、进度、音量、壁纸信息、设置到桌面 |
| ShaderEditorViewModel | Pass 增删排序、参数调整、预设保存/加载、实时预览同步 |
| SettingsViewModel | 所有设置项读写、暂停策略开关、轮播配置 |
| MenuBarViewModel | 当前状态、快捷操作 |

UI 风格：Phase 1 先用基础 SwiftUI 控件搭骨架，功能跑通后再迭代视觉设计（Liquid Glass 等留到后续 Phase）。

## 数据层与服务层

### SwiftData 模型（全新设计，不兼容旧版）

```swift
@Model class Wallpaper {
    var id: UUID
    var name: String
    var filePath: String
    var type: WallpaperType          // .video / .heic / .image
    var resolution: String?
    var fileSize: Int64
    var duration: Double?
    var frameRate: Double?
    var hasAudio: Bool
    var fileHash: String             // SHA256 前 1MB
    var thumbnailPath: String?
    var isFavorite: Bool
    var volumeOverride: Int?         // nil = 跟随全局
    var importDate: Date
    var tags: [Tag]                  // 多对多
    var shaderPreset: ShaderPreset?  // 一对一
}

@Model class Tag {
    var id: UUID
    var name: String
    var color: String
    var wallpapers: [Wallpaper]
}

@Model class ShaderPreset {
    var id: UUID
    var name: String
    var passesJSON: String           // [ShaderPassConfig] 序列化
    var isBuiltIn: Bool              // 内置预设不可删除
    var createdAt: Date
    var wallpaper: Wallpaper?
}

@Model class Settings {
    // 播放
    var loopMode: String             // "loop" / "once"
    var playbackRate: Double
    var randomStartPosition: Bool
    // 音频
    var globalVolume: Int
    var defaultMuted: Bool
    var previewOnlyAudio: Bool
    var audioDuckingEnabled: Bool
    var audioScreenId: String?
    // 性能
    var fpsLimit: Int?               // nil = 不限
    var vSyncEnabled: Bool
    // 暂停策略（9 个开关）
    var pauseOnBattery: Bool
    var pauseOnFullscreen: Bool
    var pauseOnLowBattery: Bool
    var pauseOnScreenSharing: Bool
    var pauseOnHighLoad: Bool
    var pauseOnLostFocus: Bool
    var pauseOnLidClosed: Bool
    var pauseBeforeSleep: Bool
    var pauseOnOcclusion: Bool
    // 轮播
    var slideshowEnabled: Bool
    var slideshowInterval: Double
    var slideshowOrder: String
    var slideshowSource: String
    var slideshowTagId: String?
    // 显示
    var displayTopology: String
    var colorSpace: String
    var screenOrder: [String]?
    // 外观
    var themeMode: String
    var thumbnailSize: String
    var animationsEnabled: Bool
    // 系统
    var launchAtLogin: Bool
    var menuBarEnabled: Bool
    var libraryPath: String
    var appRulesJSON: String?
}
```

### Service 层迁移

| 现有模块 | 迁移策略 | 改动 |
|---------|---------|------|
| PauseStrategyManager | 去掉 WebBridge 通知，改为 `@Published` | 小 |
| PerformanceMonitor | FPS 改为读 Metal 帧率 | 中 |
| SlideshowScheduler | `onSwitchWallpaper` 改为绑定 ViewModel | 小 |
| AudioDuckingMonitor | 直接迁移 | 无 |
| DisplayManager | 窗口创建改为 MTKView | 中 |
| FileImporter | 直接迁移 | 无 |
| ThumbnailGenerator | 直接迁移 | 无 |
| FrameRateBackfiller | 直接迁移 | 无 |
| RestoreManager | 直接迁移 | 无 |
| GlobalShortcutManager | 直接迁移 | 无 |
| LaunchAtLoginManager | 直接迁移 | 无 |
| MenuBarManager | 重写为 SwiftUI MenuBarExtra | 中 |
| **FilterEngine** | **删除**，被 ShaderGraph 替代 | — |
| **WebBridge** | **删除** | — |
| **WebViewContainer** | **删除** | — |
| **AppViewModel** | **重写**，拆分为多个 ViewModel | 大 |

### 删除清单

```
删除：
  Sources/Bridge/WebBridge.swift
  Sources/Bridge/WebViewContainer.swift
  Sources/Core/FilterEngine.swift
  Sources/UI/AppViewModel.swift
  Sources/Resources/Web/plumwallpaper.html
```

## 文件结构

```
Sources/
  App/
    PlumWallPaperApp.swift
    AppDelegate.swift
  Engine/
    RenderPipeline.swift
    ScreenRenderer.swift
    VideoDecoder.swift
    ShaderGraph.swift
    ShaderPass.swift
    ParticleSystem.swift
    ParticleEmitter.swift
    Shaders.metal
    DesktopWindow.swift
  Views/
    ContentView.swift
    Library/
      LibraryView.swift
      WallpaperCard.swift
      ImportSheet.swift
      TagManagerSheet.swift
    Preview/
      PreviewView.swift
      PreviewControls.swift
    ShaderEditor/
      ShaderEditorView.swift
      PassListView.swift
      ParameterPanelView.swift
      ShaderPreviewView.swift
    Settings/
      SettingsView.swift
      PlaybackSettingsView.swift
      AudioSettingsView.swift
      PerformanceSettingsView.swift
      PauseSettingsView.swift
      DisplaySettingsView.swift
      AppearanceSettingsView.swift
      AppRulesView.swift
  ViewModels/
    LibraryViewModel.swift
    PreviewViewModel.swift
    ShaderEditorViewModel.swift
    SettingsViewModel.swift
    MenuBarViewModel.swift
  Core/
    PauseStrategyManager.swift
    PerformanceMonitor.swift
    SlideshowScheduler.swift
    AudioDuckingMonitor.swift
    DisplayManager/
      DisplayManager.swift
      ScreenInfo.swift
    FileImporter.swift
    ThumbnailGenerator.swift
    FrameRateBackfiller.swift
    RestoreManager.swift
    GlobalShortcutManager.swift
    LaunchAtLoginManager.swift
  Storage/
    Models/
      Wallpaper.swift
      Tag.swift
      ShaderPreset.swift
      Settings.swift
    WallpaperStore.swift
    PreferencesStore.swift
  System/
    DesktopBridge.swift
```

约 51 个 Swift 文件 + 1 个 Metal Shader 文件。

## 不在 Phase 1 范围内

以下功能留到后续 Phase：
- 在线壁纸源（Wallhaven / 4K / 规则引擎）→ Phase 2
- 下载管理器 → Phase 2
- Wallpaper Engine 兼容 / Workshop → Phase 3
- 循环预处理（首尾 crossfade）→ Phase 4
- 超分辨率增强 → Phase 4
- 原始壁纸保存/恢复 → Phase 4
- 每屏独立轮播配置 → Phase 4
- 国际化 / macOS 26 适配 / 锁屏预览 / Space 同步 / 自动更新 → Phase 4
- Liquid Glass 设计语言 → Phase 4
- 自定义窗口控件美化 → Phase 4
