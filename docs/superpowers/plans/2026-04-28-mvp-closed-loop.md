# MVP 闭环 + FilterEngine + 启动恢复 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成 PlumWallPaper 第一条完整闭环：导入 → 展示 → 设置壁纸 → 滤镜调节 → 启动恢复

**Architecture:** AppViewModel 作为中介层，协调 FileImporter、WallpaperEngine、FilterEngine、DisplayManager、RestoreManager。前端视图通过 @Environment 获取 AppViewModel，后端单例保持独立。

**Tech Stack:** SwiftUI, SwiftData, AVFoundation, Core Image, AppKit

---

## 文件结构

### 新增文件
- `PlumWallPaper/Sources/UI/AppViewModel.swift` — 中介层
- `PlumWallPaper/Sources/Core/FilterEngine.swift` — 滤镜引擎
- `PlumWallPaper/Sources/Core/RestoreManager.swift` — 启动恢复

### 修改文件
- `PlumWallPaper/Sources/App/PlumWallPaperApp.swift` — 注入 AppViewModel，删除占位 LibraryView
- `PlumWallPaper/Sources/Core/WallpaperEngine/WallpaperEngine.swift` — 完善 BasicVideoRenderer
- `PlumWallPaper/Sources/Core/FileImporter.swift` — 已完成，无需修改
- `PlumWallPaper/Sources/Storage/WallpaperStore.swift` — 已完成，无需修改
- `PlumWallPaper/Sources/Storage/PreferencesStore.swift` — 扩展以支持 RestoreManager

### 迁移文件
- `Sources/UI/Views/*.swift` → `PlumWallPaper/Sources/UI/Views/`（7 个视图）
- 删除根目录 `Sources/` 整个目录

---

## Task 1: 目录收敛与视图迁移

**Files:**
- Move: `Sources/UI/Views/*.swift` → `PlumWallPaper/Sources/UI/Views/`
- Delete: `Sources/` 整个目录
- Modify: `PlumWallPaper/Sources/App/PlumWallPaperApp.swift:239-249`

- [ ] **Step 1: 迁移根目录视图到 PlumWallPaper**

```bash
# 迁移 7 个视图文件
cp Sources/UI/Views/HomeView.swift PlumWallPaper/Sources/UI/Views/
cp Sources/UI/Views/LibraryView.swift PlumWallPaper/Sources/UI/Views/
cp Sources/UI/Views/ImportModalView.swift PlumWallPaper/Sources/UI/Views/
cp Sources/UI/Views/MonitorSelectorView.swift PlumWallPaper/Sources/UI/Views/
cp Sources/UI/Views/ColorAdjustView.swift PlumWallPaper/Sources/UI/Views/
cp Sources/UI/Views/SettingsView.swift PlumWallPaper/Sources/UI/Views/
cp Sources/UI/Views/WallpaperDetailView.swift PlumWallPaper/Sources/UI/Views/
```

- [ ] **Step 2: 删除 PlumWallPaperApp.swift 中的占位 LibraryView**

删除 `PlumWallPaper/Sources/App/PlumWallPaperApp.swift` 第 239-249 行：

```swift
// 删除这段
// struct LibraryView: View {
//     var body: some View {
//         ZStack {
//             Theme.bg.edgesIgnoringSafeArea(.all)
//             Text("壁纸库建设中")
//                 .font(Theme.Fonts.display(size: 48))
//                 .italic()
//         }
//     }
// }
```

- [ ] **Step 3: 删除根目录 Sources**

```bash
rm -rf Sources/
```

- [ ] **Step 4: 验证编译**

```bash
# 如果有 Xcode 工程，用 xcodebuild
cd PlumWallPaper
xcodebuild -scheme PlumWallPaper -configuration Debug build
```

预期：编译成功，无错误

- [ ] **Step 5: 提交**

```bash
git add PlumWallPaper/Sources/UI/Views/
git add PlumWallPaper/Sources/App/PlumWallPaperApp.swift
git rm -r Sources/
git commit -m "refactor: consolidate views to PlumWallPaper/Sources"
```

---

## Task 2: FilterEngine 实现

**Files:**
- Create: `PlumWallPaper/Sources/Core/FilterEngine.swift`

- [ ] **Step 1: 创建 FilterEngine.swift 骨架**

```swift
import Foundation
import AVFoundation
import CoreImage
import AppKit

/// 滤镜引擎
final class FilterEngine {
    static let shared = FilterEngine()
    private init() {}
    
    /// 为视频生成 AVVideoComposition
    func videoComposition(for asset: AVAsset, preset: FilterPreset) -> AVVideoComposition {
        // 占位，下一步实现
        fatalError("Not implemented")
    }
    
    /// 为 HEIC 应用滤镜并返回处理后的图像
    func applyToImage(at url: URL, preset: FilterPreset) -> NSImage? {
        // 占位，下一步实现
        return nil
    }
    
    /// 核心：从 FilterPreset 构建 CIImage 处理链
    func compositeCIImage(_ input: CIImage, preset: FilterPreset) -> CIImage {
        // 占位，下一步实现
        return input
    }
}
```

- [ ] **Step 2: 实现 compositeCIImage 核心逻辑**

```swift
func compositeCIImage(_ input: CIImage, preset: FilterPreset) -> CIImage {
    var output = input
    
    // 1. 曝光度
    if preset.exposure != 100 {
        let ev = (preset.exposure - 100) / 50.0
        if let filter = CIFilter(name: "CIExposureAdjust") {
            filter.setValue(output, forKey: kCIInputImageKey)
            filter.setValue(ev, forKey: kCIInputEVKey)
            if let result = filter.outputImage {
                output = result
            }
        }
    }
    
    // 2. 对比度 + 饱和度 + 黑白（合并到 CIColorControls）
    let contrast = preset.contrast / 100.0
    let saturation = (preset.saturation / 100.0) * (1.0 - preset.grayscale / 100.0)
    if let filter = CIFilter(name: "CIColorControls") {
        filter.setValue(output, forKey: kCIInputImageKey)
        filter.setValue(contrast, forKey: kCIInputContrastKey)
        filter.setValue(saturation, forKey: kCIInputSaturationKey)
        if let result = filter.outputImage {
            output = result
        }
    }
    
    // 3. 色调
    if preset.hue != 0 {
        let angle = preset.hue * .pi / 180.0
        if let filter = CIFilter(name: "CIHueAdjust") {
            filter.setValue(output, forKey: kCIInputImageKey)
            filter.setValue(angle, forKey: "inputAngle")
            if let result = filter.outputImage {
                output = result
            }
        }
    }
    
    // 4. 模糊
    if preset.blur > 0 {
        if let filter = CIFilter(name: "CIGaussianBlur") {
            filter.setValue(output, forKey: kCIInputImageKey)
            filter.setValue(preset.blur, forKey: kCIInputRadiusKey)
            if let result = filter.outputImage {
                output = result.clampedToExtent().cropped(to: input.extent)
            }
        }
    }
    
    // 5. 暗角
    if preset.vignette > 0 {
        let intensity = preset.vignette / 100.0
        if let filter = CIFilter(name: "CIVignette") {
            filter.setValue(output, forKey: kCIInputImageKey)
            filter.setValue(intensity, forKey: kCIInputIntensityKey)
            if let result = filter.outputImage {
                output = result
            }
        }
    }
    
    // 6. 颗粒感
    if preset.grain > 0 {
        let alpha = preset.grain / 100.0
        if let noiseFilter = CIFilter(name: "CIRandomGenerator"),
           let noiseImage = noiseFilter.outputImage?.cropped(to: input.extent) {
            if let blendFilter = CIFilter(name: "CISourceOverCompositing") {
                let grainImage = noiseImage.applyingFilter("CIColorMatrix", parameters: [
                    "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                    "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                    "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                    "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(alpha)),
                    "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
                ])
                blendFilter.setValue(grainImage, forKey: kCIInputImageKey)
                blendFilter.setValue(output, forKey: kCIInputBackgroundImageKey)
                if let result = blendFilter.outputImage {
                    output = result
                }
            }
        }
    }
    
    // 7. 反转
    if preset.invert > 50 {
        if let filter = CIFilter(name: "CIColorInvert") {
            filter.setValue(output, forKey: kCIInputImageKey)
            if let result = filter.outputImage {
                output = result
            }
        }
    }
    
    return output
}
```


- [ ] **Step 3: 实现 videoComposition 和 applyToImage**

```swift
func videoComposition(for asset: AVAsset, preset: FilterPreset) -> AVVideoComposition {
    return AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
        let output = self.compositeCIImage(request.sourceImage, preset: preset)
        request.finish(with: output, context: nil)
    })
}

func applyToImage(at url: URL, preset: FilterPreset) -> NSImage? {
    guard let ciImage = CIImage(contentsOf: url) else { return nil }
    let output = compositeCIImage(ciImage, preset: preset)
    let context = CIContext()
    guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
    return NSImage(cgImage: cgImage, size: NSSize(width: output.extent.width, height: output.extent.height))
}
```

- [ ] **Step 4: 提交**

```bash
git add PlumWallPaper/Sources/Core/FilterEngine.swift
git commit -m "feat: implement FilterEngine with 9-parameter CIFilter chain"
```

---

## Task 3: WallpaperEngine 滤镜支持

**Files:**
- Modify: `PlumWallPaper/Sources/Core/WallpaperEngine/WallpaperEngine.swift`

- [ ] **Step 1: 让 BasicVideoRenderer 支持滤镜**

替换 `BasicVideoRenderer` 中 `start()` 和 `applyFilter()` 方法：

```swift
final class BasicVideoRenderer: WallpaperRenderer {
    private let wallpaper: Wallpaper
    private let screen: NSScreen
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var hostingWindow: NSWindow?
    private var looper: AVPlayerLooper?
    private var currentItem: AVPlayerItem?
    
    init(wallpaper: Wallpaper, screen: NSScreen) {
        self.wallpaper = wallpaper
        self.screen = screen
    }
    
    func start() {
        let asset = AVAsset(url: URL(fileURLWithPath: wallpaper.filePath))
        let item = AVPlayerItem(asset: asset)
        if let preset = wallpaper.filterPreset {
            item.videoComposition = FilterEngine.shared.videoComposition(for: asset, preset: preset)
        }
        let queuePlayer = AVQueuePlayer(playerItem: item)
        self.looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        self.player = queuePlayer
        self.currentItem = item
        
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) - 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = true
        
        let contentView = NSView(frame: screen.frame)
        contentView.wantsLayer = true
        let layer = AVPlayerLayer(player: queuePlayer)
        layer.frame = contentView.bounds
        layer.videoGravity = .resizeAspectFill
        contentView.layer?.addSublayer(layer)
        window.contentView = contentView
        window.orderBack(nil)
        
        self.playerLayer = layer
        self.hostingWindow = window
        
        queuePlayer.play()
    }
    
    func applyFilter(_ preset: FilterPreset) {
        guard let item = currentItem else { return }
        let asset = item.asset
        item.videoComposition = FilterEngine.shared.videoComposition(for: asset, preset: preset)
    }
    
    func removeFilter() {
        currentItem?.videoComposition = nil
    }
    
    // stop, pause, resume 保持不变
}
```

- [ ] **Step 2: 让 HEICRenderer 支持滤镜**

修改 `WallpaperEngine.swift` 中的 `HEICRenderer.applyFilter`：

```swift
extension HEICRenderer {
    func applyFilter(_ preset: FilterPreset) {
        let url = URL(fileURLWithPath: wallpaper.filePath)
        guard let processedImage = FilterEngine.shared.applyToImage(at: url, preset: preset) else { return }
        // 写到临时文件供 NSWorkspace 使用
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("plum_filter_\(wallpaper.id.uuidString).png")
        if let tiff = processedImage.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: tmpURL)
            try? desktopBridge.setDesktopImage(tmpURL, for: screen)
        }
    }
}
```

注意：HEICRenderer 已经在 `WallpaperRenderer.swift` 里定义了基本壳子，这里需要把 `applyFilter` 的实际实现填进去。

- [ ] **Step 3: WallpaperEngine 暴露 applyFilter 接口**

在 WallpaperEngine 类中添加：

```swift
/// 对正在显示的壁纸应用滤镜
func applyFilter(_ preset: FilterPreset, to wallpaper: Wallpaper) {
    for renderer in renderers.values {
        renderer.applyFilter(preset)
    }
}
```

- [ ] **Step 4: 提交**

```bash
git add PlumWallPaper/Sources/Core/WallpaperEngine/
git commit -m "feat: integrate FilterEngine into WallpaperEngine renderers"
```

---

## Task 4: RestoreManager 实现

**Files:**
- Create: `PlumWallPaper/Sources/Core/RestoreManager.swift`

- [ ] **Step 1: 创建 RestoreManager.swift**

```swift
import Foundation
import SwiftData
import AppKit

/// 启动恢复管理器
@MainActor
final class RestoreManager {
    static let shared = RestoreManager()
    private let key = "activeWallpaperMapping"
    
    private init() {}
    
    /// 保存当前会话（screenID -> wallpaper UUID）
    func saveSession(mapping: [String: UUID]) {
        let dict = mapping.mapValues { $0.uuidString }
        UserDefaults.standard.set(dict, forKey: key)
    }
    
    /// 加载持久化映射
    func loadSession() -> [String: UUID] {
        guard let dict = UserDefaults.standard.dictionary(forKey: key) as? [String: String] else {
            return [:]
        }
        var mapping: [String: UUID] = [:]
        for (screenID, uuidString) in dict {
            if let uuid = UUID(uuidString: uuidString) {
                mapping[screenID] = uuid
            }
        }
        return mapping
    }
    
    /// 恢复上次会话
    func restoreSession(
        context: ModelContext,
        displayManager: DisplayManager,
        wallpaperEngine: WallpaperEngine
    ) async {
        let mapping = loadSession()
        guard !mapping.isEmpty else { return }
        
        for screen in displayManager.availableScreens {
            guard let wallpaperID = mapping[screen.id] else { continue }
            let descriptor = FetchDescriptor<Wallpaper>(
                predicate: #Predicate { $0.id == wallpaperID }
            )
            do {
                if let wallpaper = try context.fetch(descriptor).first {
                    wallpaperEngine.setWallpaper(wallpaper, for: screen)
                }
            } catch {
                // 静默跳过
                continue
            }
        }
    }
}
```

注意：使用 `Wallpaper.id`（UUID）而非 `PersistentIdentifier`，因为 UUID 的序列化更简单且 Wallpaper 模型已带 UUID。

- [ ] **Step 2: 提交**

```bash
git add PlumWallPaper/Sources/Core/RestoreManager.swift
git commit -m "feat: add RestoreManager for per-screen wallpaper persistence"
```

---

## Task 5: AppViewModel 实现

**Files:**
- Create: `PlumWallPaper/Sources/UI/AppViewModel.swift`

- [ ] **Step 1: 创建 AppViewModel.swift**

```swift
import Foundation
import SwiftData
import AppKit
import Observation

/// 应用主 ViewModel：前后端中介层
@Observable
@MainActor
final class AppViewModel {
    // 后端引用
    let engine = WallpaperEngine.shared
    let display = DisplayManager.shared
    let importer = FileImporter.shared
    let filter = FilterEngine.shared
    let restore = RestoreManager.shared
    
    // 导入状态
    var isImporting = false
    var importProgress: Double = 0
    var currentImportFileName = ""
    var importErrorMessage: String? = nil
    
    // 重复确认
    var pendingDuplicates: [URL] = []
    
    // 壁纸状态
    var activeWallpaperPerScreen: [String: Wallpaper] = [:]
    
    // 多屏选择信号
    var monitorSelectorRequest: Wallpaper? = nil
    
    // MARK: - 导入
    
    /// 主导入入口：先扫描重复，再实际导入
    func importFiles(urls: [URL], context: ModelContext) async {
        let store = WallpaperStore(modelContext: context)
        isImporting = true
        importProgress = 0
        importErrorMessage = nil
        defer { isImporting = false }
        
        var unique: [URL] = []
        var dupes: [URL] = []
        
        for url in urls {
            // 用快速哈希判重前先存全部，重哈希交给 importFile
            do {
                let tempHash = try await quickHash(url: url)
                if try store.wallpaperExists(fileHash: tempHash) {
                    dupes.append(url)
                } else {
                    unique.append(url)
                }
            } catch {
                continue
            }
        }
        
        // 先导入不重复的
        await actuallyImport(urls: unique, context: context, allowSuffix: false)
        
        // 把重复的暂存，等用户确认
        if !dupes.isEmpty {
            pendingDuplicates = dupes
        }
    }
    
    /// 用户确认重复导入：自动加 (2) 后缀
    func confirmDuplicates(context: ModelContext) async {
        let urls = pendingDuplicates
        pendingDuplicates = []
        await actuallyImport(urls: urls, context: context, allowSuffix: true)
    }
    
    /// 取消重复导入
    func cancelDuplicates() {
        pendingDuplicates = []
    }
    
    private func actuallyImport(urls: [URL], context: ModelContext, allowSuffix: Bool) async {
        let store = WallpaperStore(modelContext: context)
        let total = max(urls.count, 1)
        
        for (idx, url) in urls.enumerated() {
            currentImportFileName = url.lastPathComponent
            do {
                let wallpaper = try await importer.importFile(url: url)
                if allowSuffix {
                    wallpaper.name = uniqueName(base: wallpaper.name, store: store)
                }
                try store.addWallpaper(wallpaper)
            } catch {
                importErrorMessage = "导入失败: \(url.lastPathComponent)"
            }
            importProgress = Double(idx + 1) / Double(total)
        }
    }
    
    private func quickHash(url: URL) async throws -> String {
        // 取文件首 1MB 的哈希作为快速指纹（与 FileImporter 不同——这里只为查重）
        // 简化：直接读全文，哈希函数同 FileImporter
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: 1024 * 1024) ?? Data()
        return data.sha256()
    }
    
    private func uniqueName(base: String, store: WallpaperStore) -> String {
        var candidate = base
        var idx = 2
        while existingNameCount(name: candidate, store: store) > 0 {
            candidate = "\(base) (\(idx))"
            idx += 1
        }
        return candidate
    }
    
    private func existingNameCount(name: String, store: WallpaperStore) -> Int {
        do {
            let all = try store.fetchAllWallpapers()
            return all.filter { $0.name == name }.count
        } catch {
            return 0
        }
    }
    
    // MARK: - 设壁纸
    
    func smartSetWallpaper(_ wallpaper: Wallpaper) {
        if display.availableScreens.count <= 1, let screen = display.availableScreens.first {
            setWallpaper(wallpaper, for: screen)
        } else {
            monitorSelectorRequest = wallpaper
        }
    }
    
    func setWallpaper(_ wallpaper: Wallpaper, for screen: ScreenInfo) {
        engine.setWallpaper(wallpaper, for: screen)
        activeWallpaperPerScreen[screen.id] = wallpaper
        wallpaper.lastUsedDate = Date()
        persistMapping()
    }
    
    func setWallpaperToAll(_ wallpaper: Wallpaper) {
        for screen in display.availableScreens {
            engine.setWallpaper(wallpaper, for: screen)
            activeWallpaperPerScreen[screen.id] = wallpaper
        }
        wallpaper.lastUsedDate = Date()
        persistMapping()
    }
    
    private func persistMapping() {
        let map = activeWallpaperPerScreen.mapValues { $0.id }
        restore.saveSession(mapping: map)
    }
    
    // MARK: - 滤镜
    
    func applyFilter(_ preset: FilterPreset, to wallpaper: Wallpaper) {
        engine.applyFilter(preset, to: wallpaper)
    }
    
    // MARK: - 启动恢复
    
    func restoreLastSession(context: ModelContext) async {
        await restore.restoreSession(
            context: context,
            displayManager: display,
            wallpaperEngine: engine
        )
        // 把恢复后的状态同步到 activeWallpaperPerScreen
        let mapping = restore.loadSession()
        for (screenID, uuid) in mapping {
            let descriptor = FetchDescriptor<Wallpaper>(
                predicate: #Predicate { $0.id == uuid }
            )
            if let wallpaper = try? context.fetch(descriptor).first {
                activeWallpaperPerScreen[screenID] = wallpaper
            }
        }
    }
}

// MARK: - 工具

private extension Data {
    func sha256() -> String {
        // 直接复用 CryptoKit
        import_CryptoKit_sha256(self)
    }
}

import CryptoKit
private func import_CryptoKit_sha256(_ data: Data) -> String {
    let digest = SHA256.hash(data: data)
    return digest.compactMap { String(format: "%02x", $0) }.joined()
}
```

注意：由于 Swift 不允许在文件内的函数体中 `import`，把 `import CryptoKit` 移到文件顶部，并把哈希函数简化为顶部直接定义的私有函数。

- [ ] **Step 2: 修正 import 位置**

把文件最上方的 import 改成：

```swift
import Foundation
import SwiftData
import AppKit
import Observation
import CryptoKit
```

并把文件末尾的工具函数简化为：

```swift
private extension Data {
    func sha256() -> String {
        let digest = SHA256.hash(data: self)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
```

删除 `import_CryptoKit_sha256` 那段。

- [ ] **Step 3: 提交**

```bash
git add PlumWallPaper/Sources/UI/AppViewModel.swift
git commit -m "feat: add AppViewModel as frontend-backend mediator"
```

---

## Task 6: 注入 AppViewModel 到 App

**Files:**
- Modify: `PlumWallPaper/Sources/App/PlumWallPaperApp.swift`

- [ ] **Step 1: 在 PlumWallPaperApp 中持有 AppViewModel**

把 `PlumWallPaperApp` 改成：

```swift
@main
struct PlumWallPaperApp: App {
    let modelContainer: ModelContainer
    @State private var viewModel = AppViewModel()

    init() {
        do {
            let schema = Schema([
                Wallpaper.self,
                Tag.self,
                FilterPreset.self,
                Settings.self
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(.dark)
                .modelContainer(modelContainer)
                .environment(viewModel)
                .task {
                    await viewModel.restoreLastSession(context: modelContainer.mainContext)
                }
                .onAppear {
                    if let window = NSApplication.shared.windows.first {
                        window.titleVisibility = .hidden
                        window.titlebarAppearsTransparent = true
                        window.styleMask.insert(.fullSizeContentView)
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
```

- [ ] **Step 2: 让 MainView 监听 monitorSelectorRequest**

修改 MainView：

```swift
struct MainView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var activeTab: String = "home"
    @State private var showSettings = false
    @State private var showImport = false

    var body: some View {
        @Bindable var vm = viewModel
        
        ZStack(alignment: .top) {
            // ...原有内容保持不变...
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .sheet(isPresented: $showImport) {
            ImportModalView()
        }
        .sheet(item: $vm.monitorSelectorRequest) { wallpaper in
            MonitorSelectorView(wallpaper: wallpaper)
        }
    }
}
```

注意：`Wallpaper` 必须是 `Identifiable` —— LibraryView 已经有 `extension Wallpaper: Identifiable {}`。如果没有则添加。

- [ ] **Step 3: 提交**

```bash
git add PlumWallPaper/Sources/App/PlumWallPaperApp.swift
git commit -m "feat: inject AppViewModel and wire monitor selector sheet"
```

---

## Task 7: HomeView 接通后端

**Files:**
- Modify: `PlumWallPaper/Sources/UI/Views/HomeView.swift:143-145`

- [ ] **Step 1: 在 HomeView 中获取 AppViewModel**

在 `HomeView` 顶部添加：

```swift
@Environment(AppViewModel.self) private var viewModel
```

- [ ] **Step 2: 替换 setWallpaper 实现**

把现有的：

```swift
func setWallpaper(_ wallpaper: Wallpaper) {
    // TODO: 调用后端 WallpaperEngine
}
```

改为：

```swift
func setWallpaper(_ wallpaper: Wallpaper) {
    viewModel.smartSetWallpaper(wallpaper)
}
```

- [ ] **Step 3: 提交**

```bash
git add PlumWallPaper/Sources/UI/Views/HomeView.swift
git commit -m "feat: wire HomeView setWallpaper button to AppViewModel"
```

---

## Task 8: LibraryView 接通后端

**Files:**
- Modify: `PlumWallPaper/Sources/UI/Views/LibraryView.swift`

- [ ] **Step 1: 注入 AppViewModel**

在 LibraryView 顶部添加：

```swift
@Environment(AppViewModel.self) private var viewModel
```

- [ ] **Step 2: 改造 contextMenu 中的"设为壁纸"**

把：

```swift
Button { showingMonitorSelector = wallpaper } label: {
    Label("设为壁纸", systemImage: "desktopcomputer")
}
```

改为：

```swift
Button { viewModel.smartSetWallpaper(wallpaper) } label: {
    Label("设为壁纸", systemImage: "desktopcomputer")
}
```

并删除 `@State private var showingMonitorSelector` 以及对应的 `.sheet(item: $showingMonitorSelector)`（因为现在 MonitorSelectorView 由 MainView 统一管理）。

- [ ] **Step 3: 提交**

```bash
git add PlumWallPaper/Sources/UI/Views/LibraryView.swift
git commit -m "feat: wire LibraryView context menu to AppViewModel"
```

---

## Task 9: ImportModalView 接通后端

**Files:**
- Modify: `PlumWallPaper/Sources/UI/Views/ImportModalView.swift`

- [ ] **Step 1: 注入 AppViewModel 和 modelContext**

在 ImportModalView 顶部添加：

```swift
@Environment(AppViewModel.self) private var viewModel
@Environment(\.modelContext) private var modelContext
```

并删除现有的本地 `@State private var importProgress: Double = 0.0` 等状态——改为绑定 ViewModel：

```swift
@State private var isDragging = false
@State private var showDuplicateConfirm = false
```

- [ ] **Step 2: 替换 simulateImport 为真实导入**

删除 `simulateImport()` 函数。把 `selectFiles`、`selectFolder`、`handleDrop` 改为：

```swift
func selectFiles() {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = true
    panel.canChooseDirectories = false
    panel.allowedContentTypes = [.movie, .image]
    if panel.runModal() == .OK {
        Task { await runImport(urls: panel.urls) }
    }
}

func selectFolder() {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    if panel.runModal() == .OK {
        guard let folderURL = panel.urls.first else { return }
        let urls = collectMediaFiles(in: folderURL)
        Task { await runImport(urls: urls) }
    }
}

func handleDrop(_ providers: [NSItemProvider]) {
    Task {
        var urls: [URL] = []
        for provider in providers {
            if let url = await loadURL(from: provider) {
                urls.append(url)
            }
        }
        await runImport(urls: urls)
    }
}

private func runImport(urls: [URL]) async {
    await viewModel.importFiles(urls: urls, context: modelContext)
    if !viewModel.pendingDuplicates.isEmpty {
        showDuplicateConfirm = true
    } else if !viewModel.isImporting {
        dismiss()
    }
}

private func loadURL(from provider: NSItemProvider) async -> URL? {
    await withCheckedContinuation { continuation in
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            if let data = item as? Data,
               let url = URL(dataRepresentation: data, relativeTo: nil) {
                continuation.resume(returning: url)
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
}

private func collectMediaFiles(in folder: URL) -> [URL] {
    let exts = ["mp4", "mov", "m4v", "heic", "heif"]
    guard let enumerator = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: nil) else {
        return []
    }
    var urls: [URL] = []
    for case let fileURL as URL in enumerator {
        if exts.contains(fileURL.pathExtension.lowercased()) {
            urls.append(fileURL)
        }
    }
    return urls
}
```

- [ ] **Step 3: 进度环改为绑定 ViewModel**

把 `if !isImporting { ... } else { ... }` 改为 `if !viewModel.isImporting`，进度环显示 `viewModel.importProgress`，文件名显示 `viewModel.currentImportFileName`。

- [ ] **Step 4: 添加重复确认弹层**

在 ImportModalView 的 body 末尾添加：

```swift
.confirmationDialog(
    "检测到 \(viewModel.pendingDuplicates.count) 个重复文件",
    isPresented: $showDuplicateConfirm
) {
    Button("仍要导入（自动加 (2) 后缀）") {
        Task {
            await viewModel.confirmDuplicates(context: modelContext)
            dismiss()
        }
    }
    Button("跳过重复", role: .cancel) {
        viewModel.cancelDuplicates()
        dismiss()
    }
} message: {
    Text("库中已有相同文件。要不要仍然导入它们？")
}
```

- [ ] **Step 5: 提交**

```bash
git add PlumWallPaper/Sources/UI/Views/ImportModalView.swift
git commit -m "feat: wire ImportModalView to FileImporter via AppViewModel"
```

---

## Task 10: MonitorSelectorView 接通后端

**Files:**
- Modify: `PlumWallPaper/Sources/UI/Views/MonitorSelectorView.swift`

- [ ] **Step 1: 注入 AppViewModel 并删除 mock screens**

替换文件中 MonitorSelectorView 的开头部分：

```swift
struct MonitorSelectorView: View {
    let wallpaper: Wallpaper
    @Environment(\.dismiss) var dismiss
    @Environment(AppViewModel.self) private var viewModel
    
    var screens: [ScreenInfo] {
        viewModel.display.availableScreens
    }
    
    @State private var selectedScreenId: String? = nil
    
    // body 保持不变
    // ...
```

注意：删除原文件第 14-18 行硬编码的 mock `screens` 数组。

- [ ] **Step 2: 替换 applyToSelected 和 applyToAll**

```swift
func applyToSelected() {
    guard let screenId = selectedScreenId,
          let screen = screens.first(where: { $0.id == screenId }) else { return }
    viewModel.setWallpaper(wallpaper, for: screen)
    viewModel.monitorSelectorRequest = nil
    dismiss()
}

func applyToAll() {
    viewModel.setWallpaperToAll(wallpaper)
    viewModel.monitorSelectorRequest = nil
    dismiss()
}
```

- [ ] **Step 3: 删除文件顶部冗余的 ScreenInfo 定义**

`ScreenInfo` 已在 DisplayManager 体系中定义（`DisplayManager.swift` 中通过 `MonitorSelectorView` 的同名结构体共用）。检查一下：如果 DisplayManager 那边定义了 ScreenInfo，本文件顶部第 3-8 行的 `ScreenInfo struct` 必须删除以避免重复定义。

实际状况：当前 ScreenInfo 是定义在 MonitorSelectorView.swift 文件最顶部的，DisplayManager.swift 中只有引用没有定义。所以需要：

把 `MonitorSelectorView.swift` 顶部的 ScreenInfo 提到独立位置（或者保留在此文件，因为 DisplayManager 会引用同一个文件）。**保持原样**：ScreenInfo 留在 MonitorSelectorView.swift，DisplayManager.swift 会从同一 module 引用到。

- [ ] **Step 4: 提交**

```bash
git add PlumWallPaper/Sources/UI/Views/MonitorSelectorView.swift
git commit -m "feat: wire MonitorSelectorView to real DisplayManager and AppViewModel"
```

---

## Task 11: ColorAdjustView 接通滤镜引擎

**Files:**
- Modify: `PlumWallPaper/Sources/UI/Views/ColorAdjustView.swift:146-163`

- [ ] **Step 1: 注入 AppViewModel**

在 ColorAdjustView 顶部添加：

```swift
@Environment(AppViewModel.self) private var viewModel
```

- [ ] **Step 2: 改造 applyFilter 函数**

把现有：

```swift
func applyFilter() {
    let preset = wallpaper.filterPreset ?? FilterPreset(name: "Custom")
    preset.exposure = exposure
    // ...
    wallpaper.filterPreset = preset
    try? modelContext.save()
    
    // TODO: 调用后端 FilterEngine.shared.applyFilter(preset, to: wallpaper)
    dismiss()
}
```

改为：

```swift
func applyFilter() {
    let preset = wallpaper.filterPreset ?? FilterPreset(name: "Custom")
    preset.exposure = exposure
    preset.contrast = contrast
    preset.saturation = saturation
    preset.hue = hue
    preset.blur = blur
    preset.grain = grain
    preset.vignette = vignette
    preset.grayscale = grayscale
    preset.invert = invert
    
    wallpaper.filterPreset = preset
    try? modelContext.save()
    
    viewModel.applyFilter(preset, to: wallpaper)
    dismiss()
}
```

- [ ] **Step 3: 提交**

```bash
git add PlumWallPaper/Sources/UI/Views/ColorAdjustView.swift
git commit -m "feat: wire ColorAdjustView apply button to FilterEngine"
```

---

## Task 12: 完整闭环手动验证

**Files:** N/A（运行 + 验证）

- [ ] **Step 1: Build**

```bash
cd PlumWallPaper
xcodebuild -scheme PlumWallPaper -configuration Debug build
```

预期：BUILD SUCCEEDED

- [ ] **Step 2: 运行 App**

在 Xcode 中按 Cmd+R 启动 App。

- [ ] **Step 3: 验证导入流程**

- 点击右上角 + 按钮，弹出 ImportModalView
- 选择一个 .mp4 文件
- 看到进度环走完，库中出现新壁纸

- [ ] **Step 4: 验证重复导入**

- 再次导入同一个 .mp4 文件
- 应该弹出"检测到 1 个重复文件"对话框
- 点击"仍要导入"
- 库中出现 `<原名> (2)`

- [ ] **Step 5: 验证设为壁纸（单屏）**

- 在 HomeView 点击"设为壁纸"
- 桌面壁纸应该立刻变成视频壁纸

- [ ] **Step 6: 验证设为壁纸（多屏）**

如果有外接显示器：
- 在 HomeView 点击"设为壁纸"
- 应该弹出 MonitorSelectorView
- 显示真实的显示器列表（不是 mock）
- 选择一个显示器，应用成功

- [ ] **Step 7: 验证滤镜**

- 在 LibraryView 右键某个壁纸 → 色彩调节
- 调高对比度滑块到 150
- 点"应用修改"
- 桌面壁纸应该变化

- [ ] **Step 8: 验证启动恢复**

- 完全退出 App（Cmd+Q）
- 重新启动 App
- 桌面壁纸应该自动恢复到上次状态

- [ ] **Step 9: 提交最终结果**

```bash
git add -A
git commit -m "chore: complete MVP closed-loop verification" --allow-empty
git push origin main
```

---

## 完成标准

- ✅ 导入流程：选择/拖拽/文件夹三种方式都能导入
- ✅ 重复检测：弹出确认 → 加 (2) 后缀
- ✅ 设为壁纸：单屏直接，多屏弹选择器
- ✅ 滤镜：9 参数生效，桌面真实变化
- ✅ 启动恢复：每屏独立恢复
- ✅ 目录结构：`PlumWallPaper/Sources/*` 是唯一真源

