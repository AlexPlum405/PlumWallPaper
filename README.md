# PlumWallPaper

> macOS 动态壁纸引擎 — 视频 / HEIC 壁纸 · 多显示器 · 实时滤镜
>
> Dynamic wallpaper engine for macOS — Video / HEIC wallpapers · Multi-display · Real-time filters

---

## 功能 / Features

| 功能 | Feature | 状态 / Status |
|------|---------|--------------|
| 视频壁纸（MP4/MOV） | Video wallpaper (MP4/MOV) | ✅ |
| HEIC 动态壁纸 | HEIC dynamic wallpaper | ✅ |
| 多显示器独立控制 | Per-display wallpaper control | ✅ |
| 智能显示器检测 | Smart display detection | ✅ |
| 文件导入 + 重复检测 | File import + duplicate detection | ✅ |
| 缩略图自动生成 | Auto thumbnail generation | ✅ |
| 9 参数实时滤镜 | 9-parameter real-time filters | ✅ |
| 启动自动恢复壁纸 | Auto-restore wallpaper on launch | ✅ |
| 壁纸库管理 | Wallpaper library management | ✅ |
| 轮播调度 | Slideshow scheduler | 🔜 |
| 智能省电策略 | Smart power management | 🔜 |

## 滤镜参数 / Filter Parameters

曝光度 · 对比度 · 饱和度 · 色调 · 模糊 · 颗粒感 · 暗角 · 黑白 · 反转

Exposure · Contrast · Saturation · Hue · Blur · Grain · Vignette · Grayscale · Invert

## 技术栈 / Tech Stack

- SwiftUI + SwiftData
- AVFoundation（视频渲染 / video rendering）
- Core Image（滤镜链 / filter chain）
- AppKit（桌面窗口 + NSWorkspace / desktop window + NSWorkspace）

## 系统要求 / Requirements

- macOS 14.0+
- Xcode 16.0+
- Apple Silicon / Intel

## 工程结构 / Project Structure

```
PlumWallPaper/Sources/
├── App/
│   └── PlumWallPaperApp.swift           # 入口 / Entry point
│
├── UI/                                  # ── 前端 / Frontend ──
│   ├── Theme.swift                      # 主题常量 / Theme constants
│   ├── AppViewModel.swift               # 全局状态 / Global state
│   ├── Views/
│   │   ├── HomeView.swift               # 首页 / Home
│   │   ├── LibraryView.swift            # 壁纸库 / Library
│   │   ├── ColorAdjustView.swift        # 色彩调节 / Color adjust
│   │   ├── SettingsView.swift           # 设置 / Settings
│   │   ├── ImportModalView.swift        # 导入弹窗 / Import modal
│   │   ├── MonitorSelectorView.swift    # 显示器选择 / Monitor selector
│   │   └── WallpaperDetailView.swift    # 壁纸详情 / Detail
│   └── Components/
│       ├── AdjustComponents.swift       # 调节组件 / Adjust widgets
│       └── EdgeBorder.swift             # 边框修饰 / Border modifier
│
├── Core/                                # ── 后端 / Backend ──
│   ├── WallpaperEngine/
│   │   ├── WallpaperEngine.swift        # 渲染引擎 / Render engine
│   │   └── WallpaperRenderer.swift      # Video + HEIC 渲染器 / Renderers
│   ├── DisplayManager/
│   │   └── DisplayManager.swift         # 显示器管理 / Display manager
│   ├── FilterEngine.swift               # 滤镜引擎 / Filter engine
│   ├── FileImporter.swift               # 文件导入 / File importer
│   ├── ThumbnailGenerator.swift         # 缩略图 / Thumbnail generator
│   └── RestoreManager.swift             # 启动恢复 / Session restore
│
├── Storage/                             # ── 存储 / Storage ──
│   ├── Models/
│   │   ├── Wallpaper.swift              # 壁纸模型 / Wallpaper model
│   │   ├── Tag.swift                    # 标签 / Tag
│   │   ├── FilterPreset.swift           # 滤镜预设 / Filter preset
│   │   └── Settings.swift               # 设置 / Settings
│   ├── WallpaperStore.swift             # CRUD + 查询 / CRUD + queries
│   └── PreferencesStore.swift           # 偏好 / Preferences
│
└── System/                              # ── 系统桥接 / System bridge ──
    └── DesktopBridge.swift              # NSWorkspace 封装 / NSWorkspace wrapper
```

## 构建 / Build

```bash
cd PlumWallPaper
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
```

或在 Xcode 中打开 `PlumWallPaper/PlumWallPaper.xcodeproj`，Cmd+R 运行。

Or open `PlumWallPaper/PlumWallPaper.xcodeproj` in Xcode and press Cmd+R.

## 原型 / Prototypes

| 路径 / Path | 说明 / Description |
|---|---|
| `ui-prototype/plumwallpaper-v5.html` | 最新全页 HTML 原型 / Latest full-page HTML prototype |
| `ui-prototype/home-v*.html` | 首页迭代 / Home iterations |
| `ui-prototype/color-adjustment-v*.html` | 色彩调节迭代 / Color adjust iterations |
| `ui-prototype/settings-v*.html` | 设置页迭代 / Settings iterations |
| `src/` | React/TSX 交互原型 / React/TSX interactive prototype |

## 许可 / License

MIT
