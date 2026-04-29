# PlumWallPaper 后端架构

> 更新日期: 2026-04-29

## 源码结构

```
Sources/
├── App/
│   └── PlumWallPaperApp.swift           # 入口 + SwiftData 容器
│
├── Bridge/                              # ── WebView 桥接 ──
│   ├── WebBridge.swift                  # JS↔Swift 消息路由（所有前端操作入口）
│   └── WebViewContainer.swift           # WKWebView 容器配置
│
├── Core/                                # ── 核心业务 ──
│   ├── WallpaperEngine/
│   │   ├── WallpaperEngine.swift        # 渲染调度 + BasicVideoRenderer
│   │   └── WallpaperRenderer.swift      # 渲染器协议 + HEICRenderer
│   ├── DisplayManager/
│   │   ├── DisplayManager.swift         # 多显示器检测与管理
│   │   └── ScreenInfo.swift             # 屏幕信息模型
│   ├── PauseStrategyManager.swift       # 智能暂停（事件驱动 + 轮询）
│   ├── PerformanceMonitor.swift         # FPS/GPU/内存实时监控
│   ├── FrameRateBackfiller.swift        # 启动时补全旧视频帧率
│   ├── FilterEngine.swift               # Core Image 滤镜链
│   ├── FileImporter.swift               # 文件导入 + 帧率检测
│   ├── ThumbnailGenerator.swift         # 缩略图生成
│   ├── RestoreManager.swift             # 启动恢复（UserDefaults 持久化）
│   ├── GlobalShortcutManager.swift      # 全局快捷键
│   ├── LaunchAtLoginManager.swift       # 开机启动
│   └── MenuBarManager.swift             # 菜单栏图标
│
├── Storage/                             # ── 数据层 ──
│   ├── Models/
│   │   ├── Wallpaper.swift              # 壁纸模型（含 frameRate）
│   │   ├── Tag.swift                    # 标签（多对多）
│   │   ├── FilterPreset.swift           # 滤镜预设
│   │   └── Settings.swift              # 设置 + AppRule + 枚举
│   ├── WallpaperStore.swift             # CRUD + 查询
│   └── PreferencesStore.swift           # 偏好读写
│
├── System/
│   └── DesktopBridge.swift              # NSWorkspace 桌面壁纸 API
│
├── UI/
│   └── AppViewModel.swift               # 启动恢复 + 导入流程
│
└── Resources/
    └── Web/
        ├── plumwallpaper.html           # 全部前端 UI（React 单文件）
        ├── bridge.js                    # JS 端桥接辅助
        ├── react.production.min.js
        ├── react-dom.production.min.js
        └── babel.min.js
```

## 技术栈

- Swift 5.9 / macOS 14.0+
- SwiftData（持久化）
- AVFoundation（视频渲染 + 帧率检测）
- Core Image（滤镜）
- AppKit（桌面窗口 + NSWorkspace）
- IOKit（GPU 监控 + 电源状态）
- WKWebView + React（UI）
