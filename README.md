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
| 智能暂停策略（7 种条件 + 应用黑名单） | ✅ |
| 性能监控（FPS / GPU / 内存） | ✅ |
| FPS 上限（动态检测屏幕刷新率） | ✅ |
| 视频帧率自动检测 + 库内筛选 | ✅ |

## 滤镜参数

曝光度 · 对比度 · 饱和度 · 色调 · 模糊 · 颗粒感 · 暗角 · 黑白 · 反转

## 技术栈

- WKWebView + React（UI，单文件 `plumwallpaper.html`）
- SwiftData（持久化）
- AVFoundation（视频渲染 + 帧率检测）
- Core Image（滤镜链）
- AppKit（桌面窗口 + NSWorkspace）
- IOKit（GPU 监控 + 电源状态）

## 系统要求

- macOS 14.0+
- Xcode 16.0+
- Apple Silicon / Intel

## 工程结构

```
PlumWallPaper/Sources/
├── App/
│   └── PlumWallPaperApp.swift           # 入口 + SwiftData 容器
│
├── Bridge/                              # ── WebView 桥接 ──
│   ├── WebBridge.swift                  # JS↔Swift 消息路由
│   └── WebViewContainer.swift           # WKWebView 容器
│
├── Core/                                # ── 核心业务 ──
│   ├── WallpaperEngine/
│   │   ├── WallpaperEngine.swift        # 渲染调度 + VideoRenderer
│   │   └── WallpaperRenderer.swift      # 渲染器协议 + HEICRenderer
│   ├── DisplayManager/
│   │   ├── DisplayManager.swift         # 多显示器管理
│   │   └── ScreenInfo.swift             # 屏幕信息
│   ├── PauseStrategyManager.swift       # 智能暂停策略
│   ├── PerformanceMonitor.swift         # 性能监控
│   ├── FrameRateBackfiller.swift        # 帧率补全
│   ├── FilterEngine.swift               # 滤镜引擎
│   ├── FileImporter.swift               # 文件导入
│   ├── ThumbnailGenerator.swift         # 缩略图生成
│   ├── RestoreManager.swift             # 启动恢复
│   ├── GlobalShortcutManager.swift      # 全局快捷键
│   ├── LaunchAtLoginManager.swift       # 开机启动
│   └── MenuBarManager.swift             # 菜单栏图标
│
├── Storage/                             # ── 数据层 ──
│   ├── Models/
│   │   ├── Wallpaper.swift              # 壁纸模型
│   │   ├── Tag.swift                    # 标签
│   │   ├── FilterPreset.swift           # 滤镜预设
│   │   └── Settings.swift               # 设置 + AppRule
│   ├── WallpaperStore.swift             # CRUD + 查询
│   └── PreferencesStore.swift           # 偏好管理
│
├── System/
│   └── DesktopBridge.swift              # NSWorkspace 封装
│
├── UI/
│   └── AppViewModel.swift               # 启动恢复 + 导入流程
│
└── Resources/Web/                       # ── 前端 ──
    ├── plumwallpaper.html               # 全部 UI（React 单文件）
    ├── bridge.js                        # JS 桥接辅助
    └── react/babel 运行时
```

## 构建

```bash
cd PlumWallPaper
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
```

或在 Xcode 中打开 `PlumWallPaper/PlumWallPaper.xcodeproj`，按 Cmd+R 运行。

## 许可

MIT
