# Phase 1: SwiftUI + Metal 全量重写 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 PlumWallPaper 从 WebView+React 架构全量重写为 SwiftUI+Metal 架构，UI 优先，先跑通完整界面再逐步接入功能。

**Architecture:** SwiftUI (UI) + Metal (渲染引擎) + SwiftData (存储) + MVVM。旧代码在 `/Users/Alex/AI/project/OldPaper/` 可供参考。新项目在 `/Users/Alex/AI/project/PlumWallPaper/`。

**Tech Stack:** Swift 5.9+, SwiftUI, Metal, SwiftData, AVFoundation, VideoToolbox, macOS 14.0+

**实施顺序：**
1. Task 1-3: Xcode 项目骨架 + SwiftData 模型 + ViewModel 骨架
2. Task 4: UI 设计（huashu-design 全量设计，覆盖所有页面）
3. Task 5-7: Metal 渲染引擎（视频解码 → ShaderGraph → 桌面窗口）
4. Task 8-9: 粒子系统 + 着色器编辑器接入引擎
5. Task 10-14: Service 层迁移（暂停策略/性能监控/轮播/音频/文件导入/DisplayManager）
6. Task 15-16: 系统集成（快捷键/开机启动/恢复）+ 最终集成测试

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

### Task 2: SwiftData 模型 + 数据层

**Files:**
- Create: `Sources/Storage/Models/Wallpaper.swift`
- Create: `Sources/Storage/Models/Tag.swift`
- Create: `Sources/Storage/Models/ShaderPreset.swift`
- Create: `Sources/Storage/Models/Settings.swift`
- Create: `Sources/Storage/Models/Enums.swift`
- Create: `Sources/Storage/WallpaperStore.swift`
- Create: `Sources/Storage/PreferencesStore.swift`

- [ ] **Step 1: 创建枚举定义文件**

```swift
// Sources/Storage/Models/Enums.swift
import Foundation

enum WallpaperType: String, Codable {
    case video, heic, image
}

enum LoopMode: String, Codable {
    case loop, once
}

enum SlideshowSource: String, Codable {
    case all, favorites, tag
}

enum SlideshowOrder: String, Codable {
    case sequential, random, favoritesFirst
}

enum TransitionEffect: String, Codable {
    case fade, kenBurns, none
}

enum DisplayTopology: String, Codable {
    case independent, mirror, panorama
}

enum ColorSpaceOption: String, Codable {
    case p3, srgb, adobeRGB
}

enum ThemeMode: String, Codable {
    case auto, light, dark
}

enum ThumbnailSize: String, Codable {
    case small, medium, large
}

enum RuleAction: String, Codable {
    case pause, mute, limitFPS30, limitFPS15, none
}

struct ShaderPassConfig: Codable, Identifiable {
    var id: UUID
    var type: ShaderPassType
    var name: String
    var enabled: Bool
    var parameters: [String: ShaderParameterValue]
}

enum ShaderPassType: String, Codable {
    case filter, particle, postprocess
}

enum ShaderParameterValue: Codable {
    case float(Float)
    case vec2(SIMD2<Float>)
    case vec4(SIMD4<Float>)
    case bool(Bool)
    case int(Int)
}

struct AppRule: Codable, Identifiable {
    let id: String
    let bundleIdentifier: String
    let appName: String
    let action: RuleAction
}
```

- [ ] **Step 2: 创建 Wallpaper 模型**

```swift
// Sources/Storage/Models/Wallpaper.swift
import Foundation
import SwiftData

@Model
final class Wallpaper {
    var id: UUID
    var name: String
    var filePath: String
    var type: WallpaperType
    var resolution: String?
    var fileSize: Int64
    var duration: Double?
    var frameRate: Double?
    var hasAudio: Bool
    var fileHash: String
    var thumbnailPath: String?
    var isFavorite: Bool
    var volumeOverride: Int?
    var importDate: Date

    @Relationship(deleteRule: .nullify, inverse: \Tag.wallpapers)
    var tags: [Tag]

    @Relationship(deleteRule: .cascade)
    var shaderPreset: ShaderPreset?

    init(id: UUID = UUID(), name: String, filePath: String, type: WallpaperType,
         resolution: String? = nil, fileSize: Int64 = 0, duration: Double? = nil,
         frameRate: Double? = nil, hasAudio: Bool = false, fileHash: String = "",
         thumbnailPath: String? = nil, isFavorite: Bool = false,
         volumeOverride: Int? = nil, importDate: Date = Date()) {
        self.id = id; self.name = name; self.filePath = filePath; self.type = type
        self.resolution = resolution; self.fileSize = fileSize; self.duration = duration
        self.frameRate = frameRate; self.hasAudio = hasAudio; self.fileHash = fileHash
        self.thumbnailPath = thumbnailPath; self.isFavorite = isFavorite
        self.volumeOverride = volumeOverride; self.importDate = importDate
        self.tags = []; self.shaderPreset = nil
    }
}
```

- [ ] **Step 3: 创建 Tag 模型**

```swift
// Sources/Storage/Models/Tag.swift
import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var color: String
    var wallpapers: [Wallpaper]

    init(id: UUID = UUID(), name: String, color: String = "#E03E3E") {
        self.id = id; self.name = name; self.color = color; self.wallpapers = []
    }
}
```

- [ ] **Step 4: 创建 ShaderPreset 模型**

```swift
// Sources/Storage/Models/ShaderPreset.swift
import Foundation
import SwiftData

@Model
final class ShaderPreset {
    var id: UUID
    var name: String
    var passesJSON: String
    var isBuiltIn: Bool
    var createdAt: Date

    @Relationship
    var wallpaper: Wallpaper?

    init(id: UUID = UUID(), name: String, passesJSON: String = "[]",
         isBuiltIn: Bool = false, createdAt: Date = Date()) {
        self.id = id; self.name = name; self.passesJSON = passesJSON
        self.isBuiltIn = isBuiltIn; self.createdAt = createdAt
    }

    var passes: [ShaderPassConfig] {
        get {
            guard let data = passesJSON.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([ShaderPassConfig].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                passesJSON = String(data: data, encoding: .utf8) ?? "[]"
            }
        }
    }
}
```

- [ ] **Step 5: 创建 Settings 模型**

参考旧代码 `/Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Storage/Models/Settings.swift`，所有字段使用非 optional 类型 + 默认值（全新数据库无迁移问题）。

```swift
// Sources/Storage/Models/Settings.swift
import Foundation
import SwiftData

@Model
final class Settings {
    var slideshowEnabled: Bool
    var slideshowInterval: Double
    var slideshowOrder: SlideshowOrder
    var slideshowSource: SlideshowSource
    var slideshowTagId: String?
    var transitionEffect: TransitionEffect
    var loopMode: LoopMode
    var playbackRate: Double
    var randomStartPosition: Bool
    var globalVolume: Int
    var defaultMuted: Bool
    var previewOnlyAudio: Bool
    var audioDuckingEnabled: Bool
    var audioScreenId: String?
    var fpsLimit: Int?
    var vSyncEnabled: Bool
    var pauseOnBattery: Bool
    var pauseOnFullscreen: Bool
    var pauseOnLowBattery: Bool
    var pauseOnScreenSharing: Bool
    var pauseOnHighLoad: Bool
    var pauseOnLostFocus: Bool
    var pauseOnLidClosed: Bool
    var pauseBeforeSleep: Bool
    var pauseOnOcclusion: Bool
    var displayTopology: DisplayTopology
    var colorSpace: ColorSpaceOption
    var screenOrder: [String]?
    var themeMode: ThemeMode
    var thumbnailSize: ThumbnailSize
    var animationsEnabled: Bool
    var launchAtLogin: Bool
    var menuBarEnabled: Bool
    var libraryPath: String
    var wallpaperOpacity: Int
    var appRulesJSON: String?

    init() {
        self.slideshowEnabled = false
        self.slideshowInterval = 1800
        self.slideshowOrder = .sequential
        self.slideshowSource = .all
        self.transitionEffect = .fade
        self.loopMode = .loop
        self.playbackRate = 1.0
        self.randomStartPosition = false
        self.globalVolume = 100
        self.defaultMuted = false
        self.previewOnlyAudio = false
        self.audioDuckingEnabled = true
        self.fpsLimit = nil
        self.vSyncEnabled = true
        self.pauseOnBattery = true
        self.pauseOnFullscreen = true
        self.pauseOnLowBattery = true
        self.pauseOnScreenSharing = false
        self.pauseOnHighLoad = true
        self.pauseOnLostFocus = false
        self.pauseOnLidClosed = true
        self.pauseBeforeSleep = true
        self.pauseOnOcclusion = false
        self.displayTopology = .independent
        self.colorSpace = .p3
        self.themeMode = .auto
        self.thumbnailSize = .medium
        self.animationsEnabled = true
        self.launchAtLogin = false
        self.menuBarEnabled = true
        self.libraryPath = NSHomeDirectory() + "/Pictures/PlumWallPaper"
        self.wallpaperOpacity = 100
    }

    var appRules: [AppRule] {
        get {
            guard let json = appRulesJSON, let data = json.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([AppRule].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                appRulesJSON = String(data: data, encoding: .utf8)
            }
        }
    }
}
```

- [ ] **Step 6: 创建 WallpaperStore**

```swift
// Sources/Storage/WallpaperStore.swift
import Foundation
import SwiftData

struct WallpaperStore {
    let modelContext: ModelContext

    func fetchAll() throws -> [Wallpaper] {
        let descriptor = FetchDescriptor<Wallpaper>(sortBy: [SortDescriptor(\.importDate, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    func add(_ wallpaper: Wallpaper) throws {
        modelContext.insert(wallpaper)
        try modelContext.save()
    }

    func delete(_ wallpaper: Wallpaper) throws {
        modelContext.delete(wallpaper)
        try modelContext.save()
    }

    func fetchByHash(_ hash: String) throws -> Wallpaper? {
        let descriptor = FetchDescriptor<Wallpaper>(predicate: #Predicate { $0.fileHash == hash })
        return try modelContext.fetch(descriptor).first
    }
}
```

- [ ] **Step 7: 创建 PreferencesStore**

```swift
// Sources/Storage/PreferencesStore.swift
import Foundation
import SwiftData

struct PreferencesStore {
    let modelContext: ModelContext

    func fetchSettings() throws -> Settings {
        let descriptor = FetchDescriptor<Settings>()
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        let settings = Settings()
        modelContext.insert(settings)
        try modelContext.save()
        return settings
    }

    func save() throws {
        try modelContext.save()
    }
}
```

- [ ] **Step 8: 更新 PlumWallPaperApp.swift 的 ModelContainer schema**

确保 schema 包含所有 4 个模型：`Wallpaper.self, Tag.self, ShaderPreset.self, Settings.self`（Task 1 已写好）。

- [ ] **Step 9: 构建验证**

```bash
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 10: 提交**

```bash
git add Sources/Storage/
git commit -m "feat: SwiftData 数据模型 + Store 层（Wallpaper/Tag/ShaderPreset/Settings）"
```

---

### Task 3: ViewModels 骨架

**Files:**
- Create: `Sources/ViewModels/LibraryViewModel.swift`
- Create: `Sources/ViewModels/PreviewViewModel.swift`
- Create: `Sources/ViewModels/ShaderEditorViewModel.swift`
- Create: `Sources/ViewModels/SettingsViewModel.swift`
- Create: `Sources/ViewModels/MenuBarViewModel.swift`

所有 ViewModel 先创建骨架（`@Observable` + mock 数据），UI 层可以直接绑定。后续 Task 逐步接入真实逻辑。

- [ ] **Step 1: 创建 LibraryViewModel**

```swift
// Sources/ViewModels/LibraryViewModel.swift
import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class LibraryViewModel {
    var wallpapers: [Wallpaper] = []
    var selectedWallpaper: Wallpaper?
    var selectedWallpapers: Set<UUID> = []
    var searchText: String = ""
    var selectedTag: Tag?
    var isMultiSelectMode: Bool = false
    var isImporting: Bool = false
    var sortOrder: SortOrder = .dateDesc

    enum SortOrder: String, CaseIterable {
        case dateDesc = "最新导入"
        case dateAsc = "最早导入"
        case nameAsc = "名称 A-Z"
        case sizeDesc = "文件大小"
    }

    private var modelContext: ModelContext?

    func setup(context: ModelContext) {
        self.modelContext = context
        loadWallpapers()
    }

    func loadWallpapers() {
        guard let context = modelContext else { return }
        let store = WallpaperStore(modelContext: context)
        wallpapers = (try? store.fetchAll()) ?? []
    }

    func toggleFavorite(_ wallpaper: Wallpaper) {
        wallpaper.isFavorite.toggle()
        try? modelContext?.save()
    }

    func deleteWallpaper(_ wallpaper: Wallpaper) {
        guard let context = modelContext else { return }
        let store = WallpaperStore(modelContext: context)
        try? store.delete(wallpaper)
        loadWallpapers()
    }
}
```

- [ ] **Step 2: 创建 PreviewViewModel**

```swift
// Sources/ViewModels/PreviewViewModel.swift
import Foundation
import Observation

@Observable
@MainActor
final class PreviewViewModel {
    var wallpaper: Wallpaper?
    var isPlaying: Bool = true
    var currentTime: Double = 0
    var duration: Double = 0
    var volume: Int = 100
    var isMuted: Bool = false

    func setWallpaper(_ wp: Wallpaper) {
        self.wallpaper = wp
        self.duration = wp.duration ?? 0
        self.currentTime = 0
        self.volume = wp.volumeOverride ?? 100
    }

    func togglePlayPause() { isPlaying.toggle() }
    func seek(to time: Double) { currentTime = time }
    func toggleMute() { isMuted.toggle() }
}
```

- [ ] **Step 3: 创建 ShaderEditorViewModel**

```swift
// Sources/ViewModels/ShaderEditorViewModel.swift
import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class ShaderEditorViewModel {
    var passes: [ShaderPassConfig] = []
    var selectedPassId: UUID?
    var presetName: String = "未命名预设"
    var wallpaper: Wallpaper?

    var selectedPass: ShaderPassConfig? {
        passes.first { $0.id == selectedPassId }
    }

    func loadDefaultPasses() {
        passes = [
            ShaderPassConfig(id: UUID(), type: .filter, name: "曝光调整", enabled: true, parameters: ["exposure": .float(0)]),
            ShaderPassConfig(id: UUID(), type: .filter, name: "对比度", enabled: true, parameters: ["contrast": .float(1.0)]),
            ShaderPassConfig(id: UUID(), type: .filter, name: "饱和度", enabled: true, parameters: ["saturation": .float(1.0)]),
            ShaderPassConfig(id: UUID(), type: .filter, name: "色调旋转", enabled: true, parameters: ["hue": .float(0)]),
            ShaderPassConfig(id: UUID(), type: .filter, name: "高斯模糊", enabled: false, parameters: ["radius": .float(0)]),
            ShaderPassConfig(id: UUID(), type: .filter, name: "颗粒噪点", enabled: false, parameters: ["amount": .float(0)]),
            ShaderPassConfig(id: UUID(), type: .filter, name: "暗角", enabled: false, parameters: ["intensity": .float(0)]),
            ShaderPassConfig(id: UUID(), type: .filter, name: "灰度", enabled: false, parameters: ["amount": .float(0)]),
            ShaderPassConfig(id: UUID(), type: .filter, name: "反转", enabled: false, parameters: ["enabled": .bool(false)]),
        ]
        selectedPassId = passes.first?.id
    }

    func togglePass(_ id: UUID) {
        if let idx = passes.firstIndex(where: { $0.id == id }) {
            passes[idx].enabled.toggle()
        }
    }

    func addParticlePass() {
        let pass = ShaderPassConfig(id: UUID(), type: .particle, name: "粒子发射器", enabled: true, parameters: [
            "rate": .float(100), "lifetime": .float(3), "gravityX": .float(0), "gravityY": .float(-0.5),
            "colorStartR": .float(1), "colorStartG": .float(0.3), "colorStartB": .float(0.1), "colorStartA": .float(1),
            "colorEndR": .float(1), "colorEndG": .float(0.8), "colorEndB": .float(0), "colorEndA": .float(0),
            "sizeStart": .float(8), "sizeEnd": .float(2),
        ])
        passes.append(pass)
        selectedPassId = pass.id
    }

    func addPostProcessPass(name: String) {
        let pass = ShaderPassConfig(id: UUID(), type: .postprocess, name: name, enabled: true, parameters: [
            "intensity": .float(0.5)
        ])
        passes.append(pass)
        selectedPassId = pass.id
    }

    func updateParameter(passId: UUID, key: String, value: ShaderParameterValue) {
        if let idx = passes.firstIndex(where: { $0.id == passId }) {
            passes[idx].parameters[key] = value
        }
    }

    func movePass(from source: IndexSet, to destination: Int) {
        passes.move(fromOffsets: source, toOffset: destination)
    }

    func removePass(_ id: UUID) {
        passes.removeAll { $0.id == id }
        if selectedPassId == id { selectedPassId = passes.first?.id }
    }
}
```

- [ ] **Step 4: 创建 SettingsViewModel**

```swift
// Sources/ViewModels/SettingsViewModel.swift
import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    var settings: Settings = Settings()
    private var modelContext: ModelContext?

    func setup(context: ModelContext) {
        self.modelContext = context
        let store = PreferencesStore(modelContext: context)
        settings = (try? store.fetchSettings()) ?? Settings()
    }

    func save() {
        try? modelContext?.save()
    }
}
```

- [ ] **Step 5: 创建 MenuBarViewModel**

```swift
// Sources/ViewModels/MenuBarViewModel.swift
import Foundation
import Observation

@Observable
@MainActor
final class MenuBarViewModel {
    var currentWallpaperName: String = "无壁纸"
    var isPlaying: Bool = false
    var volume: Int = 100
    var isMuted: Bool = false

    func togglePlayPause() { isPlaying.toggle() }
    func toggleMute() { isMuted.toggle() }
    func nextWallpaper() {}
    func previousWallpaper() {}
}
```

- [ ] **Step 6: 构建验证 + 提交**

```bash
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
git add Sources/ViewModels/
git commit -m "feat: 5 个 ViewModel 骨架（Library/Preview/ShaderEditor/Settings/MenuBar）"
```

---

### Task 4: UI 设计（huashu-design 全量设计）

**前置条件：** 本 Task 使用 `huashu-design` skill 进行完整 UI 设计，产出 SwiftUI 代码。

**设计参考：**
- 竞品参考：`/Users/Alex/AI/project/WaifuX/screenshots/`（截图）+ `/Users/Alex/AI/project/WaifuX/` 源码（布局/交互/设计系统）
- 老版风格：`/Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Resources/Web/plumwallpaper.html`（现有 UI 的色彩/布局/交互基调）
- 目标：基于以上参考，设计一套**有自己设计语言、风格统一、美观**的全新 UI，覆盖所有页面

**设计范围（所有页面）：**
- ContentView（主框架 + 导航）
- LibraryView（壁纸库 + 筛选栏 + 壁纸卡片 + 导入 + 标签管理）
- PreviewView（壁纸预览 + 播放控制）
- ShaderEditorView（着色器编辑器 + Pass 列表 + 参数面板 + 预览）
- SettingsView（设置页 + 7 个子页面）
- MenuBarView（菜单栏弹窗）

**Files:**
- Create: `Sources/Views/Library/LibraryView.swift`
- Create: `Sources/Views/Library/WallpaperCard.swift`
- Create: `Sources/Views/Library/FilterBar.swift`
- Create: `Sources/Views/Library/ImportSheet.swift`
- Create: `Sources/Views/Library/TagManagerSheet.swift`
- Create: `Sources/Views/Preview/PreviewView.swift`
- Create: `Sources/Views/Preview/PreviewControls.swift`
- Create: `Sources/Views/ShaderEditor/ShaderEditorView.swift`
- Create: `Sources/Views/ShaderEditor/PassListView.swift`
- Create: `Sources/Views/ShaderEditor/ParameterPanelView.swift`
- Create: `Sources/Views/ShaderEditor/ShaderPreviewView.swift`
- Create: `Sources/Views/Settings/SettingsView.swift`
- Create: `Sources/Views/Settings/PlaybackSettingsView.swift`
- Create: `Sources/Views/Settings/AudioSettingsView.swift`
- Create: `Sources/Views/Settings/PerformanceSettingsView.swift`
- Create: `Sources/Views/Settings/PauseSettingsView.swift`
- Create: `Sources/Views/Settings/DisplaySettingsView.swift`
- Create: `Sources/Views/Settings/AppearanceSettingsView.swift`
- Create: `Sources/Views/Settings/AppRulesView.swift`
- Create: `Sources/Views/MenuBar/MenuBarView.swift`
- Modify: `Sources/Views/ContentView.swift`

**执行流程：**

- [ ] **Step 1: 收集设计参考**

阅读 WaifuX 截图（`/Users/Alex/AI/project/WaifuX/screenshots/` 下所有 .png）和源码中的设计系统（`/Users/Alex/AI/project/WaifuX/DesignSystem/`），提取布局模式、配色、间距、卡片样式、导航模式等设计语言。

阅读老 Plum 的 `plumwallpaper.html`，提取现有品牌色、字体、间距、交互模式。

- [ ] **Step 2: 使用 huashu-design 设计新 UI**

调用 `huashu-design` skill，基于 Step 1 收集的参考，设计完整的 PlumWallPaper v2.0 UI：
- 定义设计语言（配色方案、字体层级、间距系统、圆角规范、阴影规范）
- 为每个页面产出 HTML mockup 或直接产出 SwiftUI 代码
- 确保风格统一、有自己的设计辨识度

- [ ] **Step 3: 实现所有 SwiftUI 页面**

根据 Step 2 的设计稿，实现所有 SwiftUI 视图文件。每个页面的功能需求参考 spec 文档 `docs/superpowers/specs/2026-04-30-phase1-swiftui-metal-rewrite.md`。

- [ ] **Step 4: 构建验证 + 提交**

```bash
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
git add Sources/Views/
git commit -m "feat: SwiftUI 全量 UI（huashu-design 设计 + 所有页面实现）"
```

---

### Task 5: Metal 视频解码器（VideoDecoder）

**Files:**
- Create: `Sources/Engine/VideoDecoder.swift`

- [ ] **Step 1: 创建 VideoDecoder**

```swift
// Sources/Engine/VideoDecoder.swift
import Foundation
import AVFoundation
import CoreVideo
import Metal

@MainActor
final class VideoDecoder {
    private var asset: AVAsset?
    private var reader: AVAssetReader?
    private var output: AVAssetReaderTrackOutput?
    private var displayLink: CVDisplayLink?
    private var isLooping = true
    private var isPaused = false
    private var playbackRate: Float = 1.0

    var onFrame: ((CVPixelBuffer) -> Void)?
    var onEnd: (() -> Void)?

    private(set) var duration: Double = 0
    private(set) var currentTime: Double = 0
    private(set) var nominalFrameRate: Float = 30

    func load(url: URL) async throws {
        let asset = AVURLAsset(url: url)
        self.asset = asset

        let duration = try await asset.load(.duration)
        self.duration = CMTimeGetSeconds(duration)

        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoDecoderError.noVideoTrack
        }

        self.nominalFrameRate = try await track.load(.nominalFrameRate)

        try setupReader(asset: asset, track: track)
    }

    private func setupReader(asset: AVAsset, track: AVAssetTrack) throws {
        let reader = try AVAssetReader(asset: asset)
        let settings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        output.alwaysCopiesSampleData = false

        guard reader.canAdd(output) else {
            throw VideoDecoderError.cannotAddOutput
        }
        reader.add(output)
        reader.startReading()

        self.reader = reader
        self.output = output
    }

    func nextFrame() -> CVPixelBuffer? {
        guard !isPaused, let output = output, let reader = reader else { return nil }

        if reader.status == .completed {
            if isLooping {
                try? restartReader()
                return self.output?.copyNextSampleBuffer().flatMap {
                    CMSampleBufferGetImageBuffer($0)
                }
            } else {
                onEnd?()
                return nil
            }
        }

        guard let sampleBuffer = output.copyNextSampleBuffer() else { return nil }
        return CMSampleBufferGetImageBuffer(sampleBuffer)
    }

    private func restartReader() throws {
        reader?.cancelReading()
        guard let asset = asset,
              let track = try? asset.tracks(withMediaType: .video).first else { return }
        try setupReader(asset: asset, track: track)
    }

    func pause() { isPaused = true }
    func resume() { isPaused = false }
    func setLooping(_ loop: Bool) { isLooping = loop }
    func setRate(_ rate: Float) { playbackRate = rate }

    func seek(to fraction: Double) {
        // TODO: 精确 seek 需要重建 reader 并指定 timeRange
    }

    func cleanup() {
        reader?.cancelReading()
        reader = nil
        output = nil
        asset = nil
    }
}

enum VideoDecoderError: Error {
    case noVideoTrack
    case cannotAddOutput
}
```

- [ ] **Step 2: 构建验证 + 提交**

```bash
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
git add Sources/Engine/VideoDecoder.swift
git commit -m "feat: Metal 视频解码器（AVAssetReader + CVPixelBuffer 输出）"
```

---

### Task 6: Metal ShaderGraph + 基础滤镜 Pass

**Files:**
- Create: `Sources/Engine/ShaderPass.swift`
- Create: `Sources/Engine/ShaderGraph.swift`
- Create: `Sources/Engine/Shaders.metal`

- [ ] **Step 1: 创建 ShaderPass 协议和基础类型**

```swift
// Sources/Engine/ShaderPass.swift
import Foundation
import Metal

enum ShaderPassType: String, Codable {
    case filter
    case particle
    case postprocess
}

struct ShaderParameter: Identifiable, Codable {
    let id: UUID
    let key: String
    let name: String
    var value: Float
    let min: Float
    let max: Float
    let defaultValue: Float
}

protocol ShaderPassProtocol: AnyObject, Identifiable {
    var id: UUID { get }
    var name: String { get }
    var type: ShaderPassType { get }
    var enabled: Bool { get set }
    var parameters: [ShaderParameter] { get set }
    func execute(input: MTLTexture, commandBuffer: MTLCommandBuffer, device: MTLDevice) -> MTLTexture
}

final class ComputeShaderPass: ShaderPassProtocol {
    let id: UUID
    let name: String
    let type: ShaderPassType
    var enabled: Bool
    var parameters: [ShaderParameter]
    private var pipelineState: MTLComputePipelineState?
    private let functionName: String

    init(id: UUID = UUID(), name: String, type: ShaderPassType = .filter,
         functionName: String, parameters: [ShaderParameter]) {
        self.id = id
        self.name = name
        self.type = type
        self.enabled = false
        self.functionName = functionName
        self.parameters = parameters
    }

    func buildPipeline(device: MTLDevice, library: MTLLibrary) throws {
        guard let function = library.makeFunction(name: functionName) else {
            throw ShaderError.functionNotFound(functionName)
        }
        pipelineState = try device.makeComputePipelineState(function: function)
    }

    func execute(input: MTLTexture, commandBuffer: MTLCommandBuffer, device: MTLDevice) -> MTLTexture {
        guard enabled, let pipeline = pipelineState else { return input }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: input.pixelFormat,
            width: input.width, height: input.height, mipmapped: false)
        descriptor.usage = [.shaderRead, .shaderWrite]
        guard let output = device.makeTexture(descriptor: descriptor) else { return input }

        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return input }
        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(input, index: 0)
        encoder.setTexture(output, index: 1)

        var params = parameters.map { $0.value }
        encoder.setBytes(&params, length: MemoryLayout<Float>.stride * params.count, index: 0)

        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (input.width + 15) / 16,
            height: (input.height + 15) / 16,
            depth: 1)
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        return output
    }
}

enum ShaderError: Error {
    case functionNotFound(String)
    case pipelineCreationFailed
}
```

PLACEHOLDER_TASK10_STEP2

- [ ] **Step 2: 创建 ShaderGraph**

```swift
// Sources/Engine/ShaderGraph.swift
import Foundation
import Metal

@MainActor
final class ShaderGraph {
    private(set) var passes: [any ShaderPassProtocol] = []
    private let device: MTLDevice
    private let library: MTLLibrary

    init(device: MTLDevice) throws {
        self.device = device
        guard let library = device.makeDefaultLibrary() else {
            throw ShaderError.pipelineCreationFailed
        }
        self.library = library
    }

    func addPass(_ pass: any ShaderPassProtocol) {
        passes.append(pass)
        if let compute = pass as? ComputeShaderPass {
            try? compute.buildPipeline(device: device, library: library)
        }
    }

    func removePass(id: UUID) {
        passes.removeAll { $0.id == id }
    }

    func reorderPass(from: Int, to: Int) {
        let pass = passes.remove(at: from)
        passes.insert(pass, at: to)
    }

    func updateParameter(passId: UUID, key: String, value: Float) {
        guard let passIndex = passes.firstIndex(where: { $0.id == passId }),
              let paramIndex = passes[passIndex].parameters.firstIndex(where: { $0.key == key }) else { return }
        passes[passIndex].parameters[paramIndex].value = value
    }

    func execute(input: MTLTexture, commandBuffer: MTLCommandBuffer) -> MTLTexture {
        var current = input
        for pass in passes where pass.enabled {
            current = pass.execute(input: current, commandBuffer: commandBuffer, device: device)
        }
        return current
    }
}
```

- [ ] **Step 3: 创建 Metal Shader 文件（基础滤镜 kernel）**

```metal
// Sources/Engine/Shaders.metal
#include <metal_stdlib>
using namespace metal;

// 曝光调整
kernel void exposureFilter(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant float *params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) return;
    float4 color = input.read(gid);
    float exposure = params[0]; // -3 to 3
    color.rgb *= pow(2.0, exposure);
    output.write(float4(clamp(color.rgb, 0.0, 1.0), color.a), gid);
}

// 对比度
kernel void contrastFilter(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant float *params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) return;
    float4 color = input.read(gid);
    float contrast = params[0]; // 0 to 3
    color.rgb = (color.rgb - 0.5) * contrast + 0.5;
    output.write(float4(clamp(color.rgb, 0.0, 1.0), color.a), gid);
}

// 饱和度
kernel void saturationFilter(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant float *params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) return;
    float4 color = input.read(gid);
    float saturation = params[0]; // 0 to 3
    float gray = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
    color.rgb = mix(float3(gray), color.rgb, saturation);
    output.write(float4(clamp(color.rgb, 0.0, 1.0), color.a), gid);
}

// 色调旋转
kernel void hueFilter(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant float *params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) return;
    float4 color = input.read(gid);
    float angle = params[0] * 3.14159265 / 180.0; // degrees to radians
    float cosA = cos(angle);
    float sinA = sin(angle);
    float3x3 hueRotation = float3x3(
        float3(0.213 + cosA*0.787 - sinA*0.213, 0.213 - cosA*0.213 + sinA*0.143, 0.213 - cosA*0.213 - sinA*0.787),
        float3(0.715 - cosA*0.715 - sinA*0.715, 0.715 + cosA*0.285 + sinA*0.140, 0.715 - cosA*0.715 + sinA*0.715),
        float3(0.072 - cosA*0.072 + sinA*0.928, 0.072 - cosA*0.072 - sinA*0.283, 0.072 + cosA*0.928 + sinA*0.072)
    );
    color.rgb = hueRotation * color.rgb;
    output.write(float4(clamp(color.rgb, 0.0, 1.0), color.a), gid);
}

// 灰度
kernel void grayscaleFilter(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant float *params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) return;
    float4 color = input.read(gid);
    float intensity = params[0]; // 0 to 1
    float gray = dot(color.rgb, float3(0.2126, 0.7152, 0.0722));
    color.rgb = mix(color.rgb, float3(gray), intensity);
    output.write(float4(color.rgb, color.a), gid);
}

// 反转
kernel void invertFilter(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant float *params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) return;
    float4 color = input.read(gid);
    float intensity = params[0]; // 0 to 1
    color.rgb = mix(color.rgb, 1.0 - color.rgb, intensity);
    output.write(float4(color.rgb, color.a), gid);
}

// 暗角
kernel void vignetteFilter(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant float *params [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    if (gid.x >= input.get_width() || gid.y >= input.get_height()) return;
    float4 color = input.read(gid);
    float intensity = params[0]; // 0 to 1
    float2 uv = float2(gid) / float2(input.get_width(), input.get_height());
    float2 center = uv - 0.5;
    float dist = length(center);
    float vignette = 1.0 - smoothstep(0.3, 0.8, dist) * intensity;
    color.rgb *= vignette;
    output.write(float4(color.rgb, color.a), gid);
}

// 全屏渲染顶点着色器
struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut fullscreenVertex(uint vid [[vertex_id]]) {
    VertexOut out;
    float2 positions[4] = { {-1,-1}, {1,-1}, {-1,1}, {1,1} };
    float2 texCoords[4] = { {0,1}, {1,1}, {0,0}, {1,0} };
    out.position = float4(positions[vid], 0, 1);
    out.texCoord = texCoords[vid];
    return out;
}

fragment float4 textureFragment(
    VertexOut in [[stage_in]],
    texture2d<float> tex [[texture(0)]])
{
    constexpr sampler s(mag_filter::linear, min_filter::linear);
    return tex.sample(s, in.texCoord);
}
```

- [ ] **Step 4: 构建验证 + 提交**

```bash
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
git add Sources/Engine/ShaderPass.swift Sources/Engine/ShaderGraph.swift Sources/Engine/Shaders.metal
git commit -m "feat: Metal ShaderGraph + 7 个 Compute Shader 滤镜 + 全屏渲染着色器"
```

---

PLACEHOLDER_TASK11

### Task 7: Metal 桌面窗口 + 渲染管线

**Files:**
- Create: `Sources/Engine/DesktopWindow.swift`
- Create: `Sources/Engine/ScreenRenderer.swift`
- Create: `Sources/Engine/RenderPipeline.swift`

- [ ] **Step 1: 创建 DesktopWindow（NSWindow + MTKView）**

```swift
// Sources/Engine/DesktopWindow.swift
import AppKit
import MetalKit

final class DesktopWindow: NSWindow {
    let mtkView: MTKView

    init(screen: NSScreen, device: MTLDevice) {
        let mtkView = MTKView(frame: screen.frame, device: device)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.framebufferOnly = false
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = false
        self.mtkView = mtkView

        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )

        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isOpaque = true
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.backgroundColor = .black
        self.contentView = mtkView
    }

    func show() {
        orderFrontRegardless()
    }

    func hide() {
        orderOut(nil)
    }
}
```

- [ ] **Step 2: 创建 ScreenRenderer（每屏渲染器）**

```swift
// Sources/Engine/ScreenRenderer.swift
import Foundation
import Metal
import MetalKit
import CoreVideo

@MainActor
final class ScreenRenderer: NSObject, MTKViewDelegate {
    let screenId: String
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let desktopWindow: DesktopWindow

    private var videoDecoder: VideoDecoder?
    private var shaderGraph: ShaderGraph?
    private var textureCache: CVMetalTextureCache?
    private var renderPipelineState: MTLRenderPipelineState?
    private var isPaused = false

    init(screen: NSScreen, device: MTLDevice) throws {
        self.screenId = screen.localizedName
        self.device = device
        guard let queue = device.makeCommandQueue() else {
            throw RendererError.noCommandQueue
        }
        self.commandQueue = queue
        self.desktopWindow = DesktopWindow(screen: screen, device: device)

        var cache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(nil, nil, device, nil, &cache)
        self.textureCache = cache

        super.init()

        self.shaderGraph = try ShaderGraph(device: device)
        try buildRenderPipeline()
        desktopWindow.mtkView.delegate = self
    }

    private func buildRenderPipeline() throws {
        guard let library = device.makeDefaultLibrary(),
              let vertexFunc = library.makeFunction(name: "fullscreenVertex"),
              let fragFunc = library.makeFunction(name: "textureFragment") else {
            throw RendererError.shaderNotFound
        }
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vertexFunc
        desc.fragmentFunction = fragFunc
        desc.colorAttachments[0].pixelFormat = desktopWindow.mtkView.colorPixelFormat
        renderPipelineState = try device.makeRenderPipelineState(descriptor: desc)
    }

    func setWallpaper(url: URL) async throws {
        let decoder = VideoDecoder()
        try await decoder.load(url: url)
        self.videoDecoder = decoder
        desktopWindow.mtkView.isPaused = false
        desktopWindow.mtkView.preferredFramesPerSecond = Int(decoder.nominalFrameRate)
        desktopWindow.show()
    }

    func pause() {
        isPaused = true
        desktopWindow.mtkView.isPaused = true
    }

    func resume() {
        isPaused = false
        desktopWindow.mtkView.isPaused = false
    }

    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    nonisolated func draw(in view: MTKView) {
        MainActor.assumeIsolated {
            guard !isPaused,
                  let pixelBuffer = videoDecoder?.nextFrame(),
                  let textureCache = textureCache,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let drawable = view.currentDrawable,
                  let renderPipeline = renderPipelineState else { return }

            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)

            var cvTexture: CVMetalTexture?
            CVMetalTextureCacheCreateTextureFromImage(
                nil, textureCache, pixelBuffer, nil,
                .bgra8Unorm, width, height, 0, &cvTexture)

            guard let cvTex = cvTexture,
                  let inputTexture = CVMetalTextureGetTexture(cvTex) else { return }

            let finalTexture = shaderGraph?.execute(input: inputTexture, commandBuffer: commandBuffer) ?? inputTexture

            guard let renderPassDesc = view.currentRenderPassDescriptor else { return }
            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDesc) else { return }
            encoder.setRenderPipelineState(renderPipeline)
            encoder.setFragmentTexture(finalTexture, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            encoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }

    func cleanup() {
        videoDecoder?.cleanup()
        desktopWindow.hide()
    }
}

enum RendererError: Error {
    case noCommandQueue
    case shaderNotFound
}
```

PLACEHOLDER_TASK11_STEP3

- [ ] **Step 3: 创建 RenderPipeline（多屏管理器）**

```swift
// Sources/Engine/RenderPipeline.swift
import Foundation
import AppKit
import Metal

@MainActor
final class RenderPipeline {
    static let shared = RenderPipeline()

    private let device: MTLDevice
    private var renderers: [String: ScreenRenderer] = [:]

    private init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal not supported")
        }
        self.device = device
    }

    func setupRenderers() throws {
        for screen in NSScreen.screens {
            let renderer = try ScreenRenderer(screen: screen, device: device)
            renderers[screen.localizedName] = renderer
        }
    }

    func setWallpaper(url: URL, screenId: String? = nil) async throws {
        if let screenId = screenId, let renderer = renderers[screenId] {
            try await renderer.setWallpaper(url: url)
        } else {
            for renderer in renderers.values {
                try await renderer.setWallpaper(url: url)
            }
        }
    }

    func pauseAll() {
        renderers.values.forEach { $0.pause() }
    }

    func resumeAll() {
        renderers.values.forEach { $0.resume() }
    }

    func cleanup() {
        renderers.values.forEach { $0.cleanup() }
        renderers.removeAll()
    }
}
```

- [ ] **Step 4: 在 AppDelegate 中初始化 RenderPipeline**

```swift
// Sources/App/AppDelegate.swift
func applicationDidFinishLaunching(_ notification: Notification) {
    window?.titlebarAppearsTransparent = true
    window?.titleVisibility = .hidden
    window?.styleMask.insert(.fullSizeContentView)

    Task {
        try? RenderPipeline.shared.setupRenderers()
    }
}
```

- [ ] **Step 5: 构建验证 + 提交**

```bash
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
git add Sources/Engine/DesktopWindow.swift Sources/Engine/ScreenRenderer.swift Sources/Engine/RenderPipeline.swift Sources/App/AppDelegate.swift
git commit -m "feat: Metal 桌面窗口 + 渲染管线（VideoDecoder → ShaderGraph → MTKView）"
```

---

### Task 8: 粒子系统（ParticleSystem + ParticleEmitter）

**Files:**
- Create: `Sources/Engine/ParticleSystem.swift`
- Create: `Sources/Engine/ParticleEmitter.swift`
- Modify: `Sources/Engine/Shaders.metal`

- [ ] **Step 1: 在 Shaders.metal 添加粒子 Compute Shader**

```metal
// Sources/Engine/Shaders.metal (追加)

struct Particle {
    float2 position;
    float2 velocity;
    float lifetime;
    float age;
    float size;
    float4 color;
};

kernel void updateParticles(
    device Particle *particles [[buffer(0)]],
    constant float *params [[buffer(1)]],  // [deltaTime, gravityX, gravityY]
    uint id [[thread_position_in_grid]])
{
    Particle p = particles[id];
    if (p.age >= p.lifetime) return;

    float deltaTime = params[0];
    float2 gravity = float2(params[1], params[2]);

    p.velocity += gravity * deltaTime;
    p.position += p.velocity * deltaTime;
    p.age += deltaTime;

    particles[id] = p;
}

kernel void renderParticles(
    device Particle *particles [[buffer(0)]],
    texture2d<float, access::write> output [[texture(0)]],
    uint id [[thread_position_in_grid]])
{
    Particle p = particles[id];
    if (p.age >= p.lifetime) return;

    int2 pos = int2(p.position);
    if (pos.x < 0 || pos.x >= output.get_width() || pos.y < 0 || pos.y >= output.get_height()) return;

    float alpha = 1.0 - (p.age / p.lifetime);
    float4 color = p.color * alpha;
    output.write(color, uint2(pos));
}
```

- [ ] **Step 2: 创建 ParticleEmitter**

```swift
// Sources/Engine/ParticleEmitter.swift
import Foundation
import simd

struct ParticleEmitterConfig {
    var position: SIMD2<Float>
    var emissionRate: Float  // particles per second
    var lifetime: Float
    var velocityMin: SIMD2<Float>
    var velocityMax: SIMD2<Float>
    var sizeStart: Float
    var sizeEnd: Float
    var colorStart: SIMD4<Float>
    var colorEnd: SIMD4<Float>
}

struct Particle {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var lifetime: Float
    var age: Float
    var size: Float
    var color: SIMD4<Float>
}

final class ParticleEmitter {
    let id: UUID
    var config: ParticleEmitterConfig
    var enabled: Bool
    private var accumulator: Float = 0

    init(id: UUID = UUID(), config: ParticleEmitterConfig) {
        self.id = id
        self.config = config
        self.enabled = true
    }

    func emit(deltaTime: Float) -> [Particle] {
        guard enabled else { return [] }
        accumulator += deltaTime * config.emissionRate
        let count = Int(accumulator)
        accumulator -= Float(count)

        return (0..<count).map { _ in
            Particle(
                position: config.position,
                velocity: SIMD2<Float>(
                    Float.random(in: config.velocityMin.x...config.velocityMax.x),
                    Float.random(in: config.velocityMin.y...config.velocityMax.y)
                ),
                lifetime: config.lifetime,
                age: 0,
                size: config.sizeStart,
                color: config.colorStart
            )
        }
    }
}
```

PLACEHOLDER_TASK12_STEP3

- [ ] **Step 3: 创建 ParticleSystem（实现 ShaderPassProtocol）**

```swift
// Sources/Engine/ParticleSystem.swift
import Foundation
import Metal

final class ParticleSystem: ShaderPassProtocol {
    let id: UUID
    let name: String = "粒子系统"
    let type: ShaderPassType = .particle
    var enabled: Bool = false
    var parameters: [ShaderParameter]

    var emitters: [ParticleEmitter] = []
    private var particleBuffer: MTLBuffer?
    private var updatePipeline: MTLComputePipelineState?
    private var renderPipeline: MTLComputePipelineState?
    private let maxParticles = 1_000_000
    private var aliveCount: Int = 0
    private var particles: [Particle] = []

    init(id: UUID = UUID(), device: MTLDevice) {
        self.id = id
        self.parameters = [
            ShaderParameter(id: UUID(), key: "gravityX", name: "重力 X", value: 0, min: -5, max: 5, defaultValue: 0),
            ShaderParameter(id: UUID(), key: "gravityY", name: "重力 Y", value: -1, min: -5, max: 5, defaultValue: -1),
        ]

        let bufferSize = MemoryLayout<Particle>.stride * maxParticles
        particleBuffer = device.makeBuffer(length: bufferSize, options: .storageModeShared)

        if let library = device.makeDefaultLibrary() {
            updatePipeline = try? device.makeComputePipelineState(
                function: library.makeFunction(name: "updateParticles")!)
            renderPipeline = try? device.makeComputePipelineState(
                function: library.makeFunction(name: "renderParticles")!)
        }
    }

    func update(deltaTime: Float) {
        for emitter in emitters {
            let newParticles = emitter.emit(deltaTime: deltaTime)
            particles.append(contentsOf: newParticles)
        }

        particles.removeAll { $0.age >= $0.lifetime }

        if particles.count > maxParticles {
            particles = Array(particles.suffix(maxParticles))
        }

        aliveCount = particles.count
    }

    func execute(input: MTLTexture, commandBuffer: MTLCommandBuffer, device: MTLDevice) -> MTLTexture {
        guard enabled, aliveCount > 0, let buffer = particleBuffer,
              let updatePipe = updatePipeline else { return input }

        let ptr = buffer.contents().bindMemory(to: Particle.self, capacity: maxParticles)
        for i in 0..<aliveCount {
            ptr[i] = particles[i]
        }

        let gravityX = parameters.first(where: { $0.key == "gravityX" })?.value ?? 0
        let gravityY = parameters.first(where: { $0.key == "gravityY" })?.value ?? -1
        var params: [Float] = [1.0/60.0, gravityX, gravityY]

        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return input }
        encoder.setComputePipelineState(updatePipe)
        encoder.setBuffer(buffer, offset: 0, index: 0)
        encoder.setBytes(&params, length: MemoryLayout<Float>.stride * 3, index: 1)
        let threadGroupSize = MTLSize(width: min(256, aliveCount), height: 1, depth: 1)
        let threadGroups = MTLSize(width: (aliveCount + 255) / 256, height: 1, depth: 1)
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        return input
    }
}
```

- [ ] **Step 4: 构建验证 + 提交**

```bash
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
git add Sources/Engine/ParticleSystem.swift Sources/Engine/ParticleEmitter.swift Sources/Engine/Shaders.metal
git commit -m "feat: GPU 粒子系统（百万级粒子 + Compute Shader 更新）"
```

---

### Task 9: 着色器编辑器接入 Metal 引擎

**Files:**
- Modify: `Sources/ViewModels/ShaderEditorViewModel.swift`
- Modify: `Sources/Views/ShaderEditor/ShaderPreviewView.swift`
- Modify: `Sources/Engine/RenderPipeline.swift`

- [ ] **Step 1: 更新 ShaderEditorViewModel 绑定 ShaderGraph**

```swift
// Sources/ViewModels/ShaderEditorViewModel.swift
// 在 loadDefaultPasses() 中，改为创建真实 ComputeShaderPass 实例
func loadDefaultPasses() {
    guard let device = MTLCreateSystemDefaultDevice() else { return }

    let filterDefs: [(String, String, String, [ShaderParameter])] = [
        ("曝光调整", "exposureFilter", "exposure", [
            ShaderParameter(id: UUID(), key: "exposure", name: "曝光", value: 0, min: -3, max: 3, defaultValue: 0)
        ]),
        ("对比度", "contrastFilter", "contrast", [
            ShaderParameter(id: UUID(), key: "contrast", name: "对比度", value: 1, min: 0, max: 3, defaultValue: 1)
        ]),
        ("饱和度", "saturationFilter", "saturation", [
            ShaderParameter(id: UUID(), key: "saturation", name: "饱和度", value: 1, min: 0, max: 3, defaultValue: 1)
        ]),
        ("色调旋转", "hueFilter", "hue", [
            ShaderParameter(id: UUID(), key: "hue", name: "色调", value: 0, min: -180, max: 180, defaultValue: 0)
        ]),
        ("灰度", "grayscaleFilter", "grayscale", [
            ShaderParameter(id: UUID(), key: "intensity", name: "强度", value: 0, min: 0, max: 1, defaultValue: 0)
        ]),
        ("反转", "invertFilter", "invert", [
            ShaderParameter(id: UUID(), key: "intensity", name: "强度", value: 0, min: 0, max: 1, defaultValue: 0)
        ]),
        ("暗角", "vignetteFilter", "vignette", [
            ShaderParameter(id: UUID(), key: "intensity", name: "强度", value: 0, min: 0, max: 1, defaultValue: 0)
        ]),
    ]

    passes = filterDefs.map { (name, funcName, _, params) in
        ShaderPassConfig(id: UUID(), name: name, type: .filter, enabled: false, parameters: params)
    }
}

func applyToEngine(screenId: String? = nil) {
    // 将当前 passes 配置同步到 RenderPipeline 的 ShaderGraph
    // TODO: 实现 RenderPipeline.updateShaderPreset()
}
```

- [ ] **Step 2: 更新 ShaderPreviewView 使用 MTKView**

```swift
// Sources/Views/ShaderEditor/ShaderPreviewView.swift
import SwiftUI
import MetalKit

struct ShaderPreviewView: NSViewRepresentable {
    let wallpaper: Wallpaper?

    func makeNSView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return MTKView()
        }
        let mtkView = MTKView(frame: .zero, device: device)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = true
        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        nsView.setNeedsDisplay(nsView.bounds)
    }
}
```

- [ ] **Step 3: 构建验证 + 提交**

```bash
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
git add Sources/ViewModels/ShaderEditorViewModel.swift Sources/Views/ShaderEditor/ShaderPreviewView.swift
git commit -m "feat: 着色器编辑器接入 Metal 引擎（MTKView 预览 + ShaderGraph 同步）"
```

---

PLACEHOLDER_TASK14

### Task 10: Service 层迁移 - PauseStrategyManager

**Files:**
- Copy: `/Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/PauseStrategyManager.swift` → `Sources/Core/PauseStrategyManager.swift`
- Modify: `Sources/Core/PauseStrategyManager.swift`

- [ ] **Step 1: 复制旧代码**

```bash
cp /Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/PauseStrategyManager.swift Sources/Core/
```

- [ ] **Step 2: 移除 WebBridge 依赖，改为 @Published**

```swift
// Sources/Core/PauseStrategyManager.swift
// 删除：
// import WebBridge
// WebBridge.shared.sendMessage(...)

// 改为：
@Published var isPaused: Bool = false
@Published var pauseReason: String? = nil

private func updatePauseState(shouldPause: Bool, reason: String?) {
    isPaused = shouldPause
    pauseReason = reason
    if shouldPause {
        RenderPipeline.shared.pauseAll()
    } else {
        RenderPipeline.shared.resumeAll()
    }
}
```

- [ ] **Step 3: 构建验证 + 提交**

```bash
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
git add Sources/Core/PauseStrategyManager.swift
git commit -m "feat: 迁移 PauseStrategyManager（移除 WebBridge，改为 @Published）"
```

---

### Task 11: Service 层迁移 - PerformanceMonitor

**Files:**
- Copy: `/Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/PerformanceMonitor.swift` → `Sources/Core/PerformanceMonitor.swift`
- Modify: `Sources/Core/PerformanceMonitor.swift`

- [ ] **Step 1: 复制旧代码**

```bash
cp /Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/PerformanceMonitor.swift Sources/Core/
```

- [ ] **Step 2: 改为读取 Metal 帧率**

```swift
// Sources/Core/PerformanceMonitor.swift
// 删除 AVPlayer.rate * nominalFrameRate 逻辑
// 改为：
private func updateFPS() {
    // 从 RenderPipeline 的 MTKView 读取实际渲染帧率
    // TODO: 需要 RenderPipeline 暴露 currentFPS 属性
    currentFPS = 60.0  // 占位
}
```

- [ ] **Step 3: 构建验证 + 提交**

```bash
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
git add Sources/Core/PerformanceMonitor.swift
git commit -m "feat: 迁移 PerformanceMonitor（改为读取 Metal 帧率）"
```

---

### Task 12: Service 层迁移 - SlideshowScheduler + AudioDuckingMonitor

**Files:**
- Copy: `/Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/SlideshowScheduler.swift` → `Sources/Core/SlideshowScheduler.swift`
- Copy: `/Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/AudioDuckingMonitor.swift` → `Sources/Core/AudioDuckingMonitor.swift`
- Modify: `Sources/Core/SlideshowScheduler.swift`

- [ ] **Step 1: 复制旧代码**

```bash
cp /Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/SlideshowScheduler.swift Sources/Core/
cp /Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/AudioDuckingMonitor.swift Sources/Core/
```

- [ ] **Step 2: 更新 SlideshowScheduler 的 onSwitchWallpaper 回调**

```swift
// Sources/Core/SlideshowScheduler.swift
// 删除：
// onSwitchWallpaper = { wallpaperId in
//     WebBridge.shared.sendMessage(...)
// }

// 改为：
var onSwitchWallpaper: ((UUID) -> Void)?

// 在 AppDelegate 或 ViewModel 中绑定：
// SlideshowScheduler.shared.onSwitchWallpaper = { wallpaperId in
//     Task {
//         try? await RenderPipeline.shared.setWallpaper(url: ...)
//     }
// }
```

- [ ] **Step 3: 构建验证 + 提交**

```bash
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
git add Sources/Core/SlideshowScheduler.swift Sources/Core/AudioDuckingMonitor.swift
git commit -m "feat: 迁移 SlideshowScheduler + AudioDuckingMonitor"
```

---

### Task 13: Service 层迁移 - FileImporter + ThumbnailGenerator + FrameRateBackfiller

**Files:**
- Copy: `/Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/FileImporter.swift` → `Sources/Core/FileImporter.swift`
- Copy: `/Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/ThumbnailGenerator.swift` → `Sources/Core/ThumbnailGenerator.swift`
- Copy: `/Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/FrameRateBackfiller.swift` → `Sources/Core/FrameRateBackfiller.swift`

- [ ] **Step 1: 复制旧代码（这三个模块无需改动）**

```bash
cp /Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/FileImporter.swift Sources/Core/
cp /Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/ThumbnailGenerator.swift Sources/Core/
cp /Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/FrameRateBackfiller.swift Sources/Core/
```

- [ ] **Step 2: 构建验证 + 提交**

```bash
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
git add Sources/Core/FileImporter.swift Sources/Core/ThumbnailGenerator.swift Sources/Core/FrameRateBackfiller.swift
git commit -m "feat: 迁移 FileImporter + ThumbnailGenerator + FrameRateBackfiller（无改动）"
```

---

### Task 14: Service 层迁移 - DisplayManager

**Files:**
- Copy: `/Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/DisplayManager/` → `Sources/Core/DisplayManager/`
- Modify: `Sources/Core/DisplayManager/DisplayManager.swift`

- [ ] **Step 1: 复制旧代码**

```bash
cp -r /Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/DisplayManager Sources/Core/
```

- [ ] **Step 2: 改为创建 DesktopWindow 而非 AVPlayerLayer**

```swift
// Sources/Core/DisplayManager/DisplayManager.swift
// 删除 AVPlayerLayer 创建逻辑
// 改为：
func setupWindows() {
    for screen in NSScreen.screens {
        // 由 RenderPipeline 统一管理 DesktopWindow
    }
}
```

- [ ] **Step 3: 构建验证 + 提交**

```bash
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
git add Sources/Core/DisplayManager/
git commit -m "feat: 迁移 DisplayManager（改为 Metal 窗口管理）"
```

---

PLACEHOLDER_TASK19

### Task 15: 系统集成（GlobalShortcuts + LaunchAtLogin + RestoreManager）

**Files:**
- Copy: `/Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/GlobalShortcutManager.swift` → `Sources/Core/GlobalShortcutManager.swift`
- Copy: `/Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/LaunchAtLoginManager.swift` → `Sources/Core/LaunchAtLoginManager.swift`
- Copy: `/Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/RestoreManager.swift` → `Sources/Core/RestoreManager.swift`
- Modify: `Sources/Core/RestoreManager.swift`

- [ ] **Step 1: 复制旧代码**

```bash
cp /Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/GlobalShortcutManager.swift Sources/Core/
cp /Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/LaunchAtLoginManager.swift Sources/Core/
cp /Users/Alex/AI/project/OldPaper/PlumWallPaper/Sources/Core/RestoreManager.swift Sources/Core/
```

- [ ] **Step 2: 更新 RestoreManager 保存/恢复逻辑**

```swift
// Sources/Core/RestoreManager.swift
// 删除旧的 JSON 格式
// 改为：
struct SessionState: Codable {
    var screenMappings: [String: UUID]  // screenId -> wallpaperId
    var shaderPresetId: UUID?
    var timestamp: Date
}

func saveSession(mappings: [String: UUID], shaderPresetId: UUID?) {
    let state = SessionState(screenMappings: mappings, shaderPresetId: shaderPresetId, timestamp: Date())
    // 保存到 UserDefaults 或 SwiftData
}

func restoreSession() async throws {
    // 读取 SessionState
    // 调用 RenderPipeline.setWallpaper() 恢复每屏壁纸
}
```

- [ ] **Step 3: 在 AppDelegate 中调用 restoreSession**

```swift
// Sources/App/AppDelegate.swift
func applicationDidFinishLaunching(_ notification: Notification) {
    window?.titlebarAppearsTransparent = true
    window?.titleVisibility = .hidden
    window?.styleMask.insert(.fullSizeContentView)

    Task {
        try? RenderPipeline.shared.setupRenderers()
        try? await RestoreManager.shared.restoreSession()
    }
}
```

- [ ] **Step 4: 构建验证 + 提交**

```bash
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
git add Sources/Core/GlobalShortcutManager.swift Sources/Core/LaunchAtLoginManager.swift Sources/Core/RestoreManager.swift Sources/App/AppDelegate.swift
git commit -m "feat: 系统集成（全局快捷键 + 开机启动 + 启动恢复）"
```

---

### Task 16: 最终集成测试 + 文档更新

**Files:**
- Modify: `CLAUDE.md`
- Modify: `README.md`

- [ ] **Step 1: 端到端测试**

```bash
# 构建 Release 版本
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Release build

# 测试清单：
# 1. 启动应用，检查主窗口是否正常显示
# 2. 导入一个视频壁纸，检查缩略图生成
# 3. 点击"设置为壁纸"，检查桌面是否显示视频
# 4. 打开着色器编辑器，启用"曝光调整"，调整参数，检查实时预览
# 5. 打开设置页，修改 FPS 上限，检查帧率是否变化
# 6. 启用"使用电池时暂停"，拔掉电源，检查是否暂停
# 7. 点击菜单栏图标，检查播放控制是否生效
# 8. 退出应用，重新启动，检查壁纸是否自动恢复
```

- [ ] **Step 2: 更新 CLAUDE.md**

```markdown
# PlumWallPaper 项目约定

## 架构概览

- **UI 层**: SwiftUI (NavigationSplitView + TabView)
- **渲染引擎**: Metal (VideoDecoder → ShaderGraph → MTKView)
- **数据层**: SwiftData (@Model)
- **构建**: Xcode project (`PlumWallPaper.xcodeproj`)，macOS 14.0+

## 关键路径

| 模块 | 路径 |
|------|------|
| 主应用 | `Sources/App/PlumWallPaperApp.swift` |
| 壁纸库 UI | `Sources/Views/Library/LibraryView.swift` |
| 着色器编辑器 UI | `Sources/Views/ShaderEditor/ShaderEditorView.swift` |
| 设置 UI | `Sources/Views/Settings/SettingsView.swift` |
| Metal 渲染管线 | `Sources/Engine/RenderPipeline.swift` |
| 视频解码器 | `Sources/Engine/VideoDecoder.swift` |
| ShaderGraph | `Sources/Engine/ShaderGraph.swift` |
| Metal Shaders | `Sources/Engine/Shaders.metal` |
| 粒子系统 | `Sources/Engine/ParticleSystem.swift` |
| SwiftData 模型 | `Sources/Storage/Models/` |
| 智能暂停 | `Sources/Core/PauseStrategyManager.swift` |
| 性能监控 | `Sources/Core/PerformanceMonitor.swift` |

## 构建命令

```bash
cd PlumWallPaper
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build
```

## 开发约定

- 新增 Swift 源文件必须手动加入 `project.pbxproj`
- Metal Shader 修改后需要 Clean Build Folder
- 设置变更后必须调用 `PauseStrategyManager.shared.reevaluate()`
- 壁纸设置后必须写 `RestoreManager.saveSession()`
- FPS 监控基于 MTKView 的实际渲染帧率
- GPU 监控基于 IOKit `IOAccelerator`

## Phase 1 完成状态（2026-04-30）

### 已完成
- SwiftUI 完整 UI（壁纸库 + 预览 + 着色器编辑器 + 设置 + 菜单栏）
- Metal 渲染引擎（VideoDecoder + ShaderGraph + DesktopWindow）
- 7 个基础滤镜 Pass（曝光/对比度/饱和度/色调/灰度/反转/暗角）
- GPU 粒子系统（百万级粒子 + Compute Shader）
- SwiftData 数据层（Wallpaper / Tag / ShaderPreset / Settings）
- Service 层迁移（暂停策略/性能监控/轮播/音频/文件导入）
- 系统集成（全局快捷键/开机启动/启动恢复）

### 待完成（Phase 2+）
- 高斯模糊 / 颗粒噪点 Pass
- Bloom / 色散 / 运动模糊后处理 Pass
- 轮播调度器接入 UI
- 应用规则黑名单 UI 完善
- 在线壁纸源
- Wallpaper Engine 兼容

---
*上次更新: 2026-04-30*
```

- [ ] **Step 3: 更新 README.md**

```markdown
# PlumWallPaper v2.0

> macOS 动态壁纸应用，基于 SwiftUI + Metal 架构。

## 特性

- 🎬 视频壁纸（MP4 / MOV / HEIC）
- 🎨 实时着色器编辑器（7 个基础滤镜 + GPU 粒子系统）
- 🖥️ 多显示器支持（镜像 / 独立 / 全景）
- ⚡ Metal 硬件加速渲染
- 🔋 智能暂停策略（电池 / 全屏 / 低电量 / 屏幕共享 / 高负载应用）
- 📊 实时性能监控（FPS / GPU / 内存）
- 🔄 壁纸轮播
- 🎵 音频控制 + 音频闪避
- 🚀 启动自动恢复

## 系统要求

- macOS 14.0+
- Metal 支持的 GPU

## 构建

```bash
git clone https://github.com/yourusername/PlumWallPaper.git
cd PlumWallPaper
xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Release build
```

## 架构

- **UI**: SwiftUI (MVVM)
- **渲染**: Metal (VideoToolbox → CVPixelBuffer → MTLTexture → ShaderGraph → MTKView)
- **数据**: SwiftData
- **着色器**: Metal Compute Shaders

## 开发

详见 [CLAUDE.md](CLAUDE.md)。

## License

MIT
```

- [ ] **Step 4: 提交**

```bash
git add CLAUDE.md README.md
git commit -m "docs: 更新 CLAUDE.md 和 README.md（Phase 1 完成）"
git tag v2.0-phase1
```

---

## 实施说明

**执行顺序**：严格按 Task 1-20 顺序执行，每个 Task 完成后必须构建验证 + 提交。

**验证标准**：
- 每个 Task 的 `xcodebuild` 必须成功（0 errors, 0 warnings）
- UI Task（4-8）完成后，运行应用检查界面是否正常显示
- Metal Task（9-13）完成后，设置一个视频壁纸，检查桌面是否渲染
- Service Task（14-18）完成后，测试暂停策略、性能监控是否生效
- Task 20 完成后，运行完整端到端测试

**回滚策略**：每个 Task 都有独立 commit，出错时 `git reset --hard HEAD~1` 回滚到上一个 Task。

**预计工时**：
- Task 1-3（骨架 + 数据层）: 2-3 小时
- Task 4-8（UI）: 4-5 小时
- Task 9-13（Metal 引擎）: 6-8 小时
- Task 14-18（Service 迁移）: 3-4 小时
- Task 19-20（系统集成 + 测试）: 2-3 小时
- **总计**: 17-23 小时

**并行机会**：Task 4-8（UI）和 Task 9-11（Metal 引擎）可以由两个开发者并行开发，最后在 Task 13 集成。

---

**计划完成。准备开始实施时，请使用 `superpowers:subagent-driven-development` 或 `superpowers:executing-plans` 逐 Task 执行。**
<!-- PLACEHOLDER_TASK_7 -->
