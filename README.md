# PlumWallPaper

> macOS 动态壁纸应用；当前仓库以 SwiftUI + Metal 原生主线为准，处于持续迭代中。

## 当前仓库状态

- 原生应用壳：AppKit 窗口管理 + SwiftUI 主界面、设置窗口、菜单栏入口
- 数据层：SwiftData 模型与本地存储（Wallpaper / Tag / ShaderPreset / Settings）
- 渲染层：Metal 渲染管线、ShaderGraph、粒子系统、视频解码器源码
- 内容层：本地壁纸库 + 在线探索（Wallhaven / 4K Wallpapers / Workshop）
- 系统集成：显示器管理、轮播、恢复、导入、下载、缓存、快捷键、开机启动
- 设计参考：`Sources/Resources/Web/plumwallpaper.html` 为历史原型资源，不是当前 UI 源码

## 当前注意事项

- 主 UI 修改入口在 `Sources/Views/` 与 `Sources/ViewModels/`
- `Sources/Core/PerformanceMonitor.swift` 目前将 `NSScreen.maximumFramesPerSecond` 作为 FPS 代理值展示，不能直接视为真实渲染 FPS
- `docs/` 目录中的进度报告、执行记录、计划文档是阶段性快照；项目根目录下的历史总结已收拢到 `docs/archive/`
- 判断当前实现时请以源码、`CLAUDE.md` 和本 README 为准
- 验证主界面时请使用 Xcode / DerivedData 的 app bundle，不要用旧的 SwiftPM `.build` 可执行文件

## 技术栈

- SwiftUI
- AppKit
- SwiftData
- Metal + MetalKit
- AVFoundation
- IOKit
- XcodeGen

## 工程结构

```text
Sources/
├── App/                 # 入口、应用代理、窗口装配
├── Views/               # SwiftUI 页面与组件
├── ViewModels/          # 页面状态与交互逻辑
├── Engine/              # Metal 渲染、解码、粒子、ShaderGraph
├── Core/                # 显示器、轮播、导入、性能监控等核心服务
├── Network/             # 在线数据源接入与抓取逻辑
├── Repositories/        # 聚合仓储层
├── OnlineModels/        # 在线内容模型
├── Services/            # 下载、缓存、壁纸设置等系统服务
├── Storage/             # SwiftData 模型与本地存储
└── Resources/           # 资源、字符串、本地 Web 原型
```

## 构建

```bash
# 修改 project.yml 后重新生成 Xcode 项目
xcodegen generate

# 构建 Debug app
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug -derivedDataPath Build/DerivedData build

# 启动 Debug app
open Build/DerivedData/Build/Products/Debug/PlumWallPaper.app
```

或直接运行：

```bash
./run.sh
```

## 许可

MIT
