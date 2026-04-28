[English](README_EN.md) | 中文

# PlumWallPaper

> macOS 动态壁纸引擎 — 视频 / HEIC 壁纸 · 多显示器 · 实时滤镜

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
| 9 参数实时滤镜 | ✅ |
| 启动自动恢复壁纸 | ✅ |
| 壁纸库管理 | ✅ |
| 轮播调度 | 🔜 |
| 智能省电策略 | 🔜 |

## 滤镜参数

曝光度 · 对比度 · 饱和度 · 色调 · 模糊 · 颗粒感 · 暗角 · 黑白 · 反转

## 技术栈

- SwiftUI + SwiftData
- AVFoundation（视频渲染）
- Core Image（滤镜链）
- AppKit（桌面窗口 + NSWorkspace）

## 系统要求

- macOS 14.0+
- Xcode 16.0+
- Apple Silicon / Intel

## 工程结构

```
PlumWallPaper/Sources/
├── App/
│   └── PlumWallPaperApp.swift           # 入口
│
├── UI/                                  # ── 前端 ──
│   ├── Theme.swift                      # 主题常量
│   ├── AppViewModel.swift               # 全局状态
│   ├── Views/
│   │   ├── HomeView.swift               # 首页
│   │   ├── LibraryView.swift            # 壁纸库
│   │   ├── ColorAdjustView.swift        # 色彩调节
│   │   ├── SettingsView.swift           # 设置
│   │   ├── ImportModalView.swift        # 导入弹窗
│   │   ├── MonitorSelectorView.swift    # 显示器选择
│   │   └── WallpaperDetailView.swift    # 壁纸详情
│   └── Components/
│       ├── AdjustComponents.swift       # 调节组件
│       └── EdgeBorder.swift             # 边框修饰
│
├── Core/                                # ── 后端 ──
│   ├── WallpaperEngine/
│   │   ├── WallpaperEngine.swift        # 渲染引擎
│   │   └── WallpaperRenderer.swift      # Video + HEIC 渲染器
│   ├── DisplayManager/
│   │   └── DisplayManager.swift         # 显示器管理
│   ├── FilterEngine.swift               # 滤镜引擎
│   ├── FileImporter.swift               # 文件导入
│   ├── ThumbnailGenerator.swift         # 缩略图生成
│   └── RestoreManager.swift             # 启动恢复
│
├── Storage/                             # ── 存储层 ──
│   ├── Models/
│   │   ├── Wallpaper.swift              # 壁纸模型
│   │   ├── Tag.swift                    # 标签
│   │   ├── FilterPreset.swift           # 滤镜预设
│   │   └── Settings.swift               # 设置
│   ├── WallpaperStore.swift             # CRUD + 查询
│   └── PreferencesStore.swift           # 偏好管理
│
└── System/                              # ── 系统桥接 ──
    └── DesktopBridge.swift              # NSWorkspace 封装
```

## 构建

```bash
cd PlumWallPaper
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
```

或在 Xcode 中打开 `PlumWallPaper/PlumWallPaper.xcodeproj`，按 Cmd+R 运行。

## 原型文件

| 路径 | 说明 |
|------|------|
| `ui-prototype/plumwallpaper-v5.html` | 最新全页 HTML 原型 |
| `ui-prototype/home-v*.html` | 首页迭代 |
| `ui-prototype/color-adjustment-v*.html` | 色彩调节迭代 |
| `ui-prototype/settings-v*.html` | 设置页迭代 |
| `src/` | React/TSX 交互原型 |

## 许可

MIT
