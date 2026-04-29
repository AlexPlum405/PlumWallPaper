# Phase 1: SwiftUI + Metal 全量重写 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 PlumWallPaper 从 WebView+React 架构全量重写为 SwiftUI+Metal 架构，UI 优先，先跑通完整界面再逐步接入功能。

**Architecture:** SwiftUI (UI) + Metal (渲染引擎) + SwiftData (存储) + MVVM。旧代码在 `/Users/Alex/AI/project/OldPaper/` 可供参考。新项目在 `/Users/Alex/AI/project/PlumWallPaper/`。

**Tech Stack:** Swift 5.9+, SwiftUI, Metal, SwiftData, AVFoundation, VideoToolbox, macOS 14.0+

**实施顺序：**
1. Task 1-3: Xcode 项目骨架 + SwiftData 模型 + 数据层
2. Task 4-8: SwiftUI 完整 UI（壁纸库 → 预览 → 着色器编辑器 → 设置 → 菜单栏）
3. Task 9-11: Metal 渲染引擎（视频解码 → ShaderGraph → 桌面窗口）
4. Task 12-13: 粒子系统 + 着色器编辑器接入引擎
5. Task 14-18: Service 层迁移（暂停策略/性能监控/轮播/音频/文件导入）
6. Task 19-20: 系统集成（快捷键/开机启动/恢复）+ 最终集成测试

---

### Task 1: Xcode 项目骨架

**Files:**
- Create: `PlumWallPaper.xcodeproj` (通过 xcodebuild)
- Create: `Sources/App/PlumWallPaperApp.swift`
- Create: `Sources/App/AppDelegate.swift`
- Create: `Sources/Views/ContentView.swift`
- Create: `Sources/Resources/Assets.xcassets/` (从旧项目复制 AppIcon)
- Create: `.gitignore`

- [ ] **Step 1: 初始化 git 仓库**

```bash
cd /Users/Alex/AI/project/PlumWallPaper
git init
```

- [ ] **Step 2: 创建 .gitignore**

```gitignore
.DS_Store
*.xcuserdata
build/
DerivedData/
.swiftpm/
*.xcworkspace
!*.xcodeproj
```

- [ ] **Step 3: 创建目录结构**

```bash
mkdir -p Sources/{App,Engine,Views/{Library,Preview,ShaderEditor,Settings},ViewModels,Core/{DisplayManager,WallpaperEngine},Storage/Models,System,Resources}
```

- [ ] **Step 4: 创建 PlumWallPaperApp.swift**

```swift
// Sources/App/PlumWallPaperApp.swift
import SwiftUI
import SwiftData

@main
struct PlumWallPaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Wallpaper.self, Tag.self, ShaderPreset.self, Settings.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
    }
}
```

- [ ] **Step 5: 创建 AppDelegate.swift**

```swift
// Sources/App/AppDelegate.swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.minSize = NSSize(width: 900, height: 600)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
```

- [ ] **Step 6: 创建 ContentView.swift（占位骨架）**

```swift
// Sources/Views/ContentView.swift
import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case library = "壁纸库"
    case shaderEditor = "着色器编辑器"
    case settings = "设置"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .library: return "photo.on.rectangle"
        case .shaderEditor: return "slider.horizontal.3"
        case .settings: return "gearshape"
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: SidebarItem? = .library

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            switch selectedItem {
            case .library:
                Text("壁纸库 - 待实现")
            case .shaderEditor:
                Text("着色器编辑器 - 待实现")
            case .settings:
                Text("设置 - 待实现")
            case nil:
                Text("选择一个页面")
            }
        }
    }
}
```

- [ ] **Step 7: 复制 AppIcon 资源**

```bash
cp -r /Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Resources/Assets.xcassets Sources/Resources/
```

- [ ] **Step 8: 使用 xcodegen 或手动创建 project.yml 生成 Xcode 项目**

```yaml
# project.yml
name: PlumWallPaper
options:
  bundleIdPrefix: com.plum
  deploymentTarget:
    macOS: "14.0"
  xcodeVersion: "16.0"
targets:
  PlumWallPaper:
    type: application
    platform: macOS
    sources:
      - Sources
    resources:
      - Sources/Resources
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.plum.wallpaper
        PRODUCT_NAME: PlumWallPaper
        MACOSX_DEPLOYMENT_TARGET: "14.0"
        SWIFT_VERSION: "5.9"
        INFOPLIST_KEY_LSUIElement: true
```

```bash
xcodegen generate
```

- [ ] **Step 9: 构建验证**

```bash
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
```

Expected: BUILD SUCCEEDED，应用启动显示 NavigationSplitView 骨架。

- [ ] **Step 10: 提交**

```bash
git add -A
git commit -m "feat: 初始化 Xcode 项目骨架 + SwiftUI NavigationSplitView"
```

---

<!-- PLACEHOLDER_TASK_2 -->
