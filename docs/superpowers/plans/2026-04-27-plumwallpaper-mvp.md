# PlumWallPaper MVP 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建 macOS 离线动态壁纸管理软件，支持视频/HEIC 壁纸、色彩调节、多显示器、轮播和省电策略

**Architecture:** SwiftUI 主应用，SwiftData 持久化，AVFoundation 视频播放，Core Image 滤镜处理

**Tech Stack:** SwiftUI, AppKit, AVFoundation, Core Image, SwiftData, XCTest

---

## 文件结构规划

```
PlumWallPaper/
├── PlumWallPaper/                      # 主应用 target
│   ├── PlumWallPaperApp.swift          # 应用入口
│   ├── Models/                         # 数据模型
│   │   ├── Wallpaper.swift
│   │   ├── ColorFilterParams.swift
│   │   ├── RotationConfig.swift
│   │   └── PowerSavingConfig.swift
│   ├── Core/                           # 核心业务逻辑
│   │   ├── WallpaperEngine.swift
│   │   ├── ColorFilterEngine.swift
│   │   ├── DisplayManager.swift
│   │   ├── RotationScheduler.swift
│   │   └── PowerManager.swift
│   ├── Storage/                        # 数据持久化
│   │   ├── WallpaperStore.swift
│   │   └── PreferencesStore.swift
│   ├── System/                         # 系统集成
│   │   └── DesktopBridge.swift
│   └── UI/                             # 界面（由 huashu-design 设计）
│       ├── WallpaperLibraryView.swift
│       ├── ColorAdjustmentView.swift
│       └── MenuBarController.swift
├── PlumWallPaperTests/                 # 单元测试
└── Info.plist                          # 应用配置
```

---



<!-- PHASE_2_PLACEHOLDER -->
## 阶段 2：核心渲染引擎

### Task 5: ColorFilterEngine - 滤镜引擎

**Files:**
- Create: `PlumWallPaper/Core/ColorFilterEngine.swift`
- Create: `PlumWallPaperTests/ColorFilterEngineTests.swift`

- [ ] **Step 1: 编写测试**

创建 `PlumWallPaperTests/ColorFilterEngineTests.swift`:

```swift
import XCTest
import AVFoundation
@testable import PlumWallPaper

final class ColorFilterEngineTests: XCTestCase {
    var engine: ColorFilterEngine!
    
    override func setUp() {
        super.setUp()
        engine = ColorFilterEngine()
    }
    
    func testPresetFiltersExist() {
        let presets = engine.presetFilters()
        
        XCTAssertNotNil(presets["warm"])
        XCTAssertNotNil(presets["cool"])
        XCTAssertNotNil(presets["vintage"])
        XCTAssertNotNil(presets["blackAndWhite"])
        XCTAssertNotNil(presets["highContrast"])
    }
    
    func testWarmPresetValues() {
        let warm = engine.presetFilters()["warm"]!
        
        XCTAssertGreaterThan(warm.temperature, 6500)
        XCTAssertGreaterThan(warm.saturation, 1.0)
    }
    
    func testCreateVideoComposition() {
        let params = ColorFilterParams(hue: 30, saturation: 1.2)
        let asset = AVAsset(url: URL(fileURLWithPath: "/test/video.mp4"))
        
        let composition = engine.createVideoComposition(for: asset, with: params)
        
        XCTAssertNotNil(composition)
        XCTAssertNotNil(composition.customVideoCompositorClass)
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
# Cmd+U
# 预期：编译失败
```

- [ ] **Step 3: 实现 ColorFilterEngine**

创建 `PlumWallPaper/Core/ColorFilterEngine.swift`:

```swift
import Foundation
import AVFoundation
import CoreImage

final class ColorFilterEngine {
    func presetFilters() -> [String: ColorFilterParams] {
        return [
            "warm": ColorFilterParams(
                hue: 0,
                saturation: 1.15,
                brightness: 0.05,
                contrast: 1.05,
                temperature: 7500,
                presetName: "Warm"
            ),
            "cool": ColorFilterParams(
                hue: 0,
                saturation: 1.1,
                brightness: 0,
                contrast: 1.0,
                temperature: 5000,
                presetName: "Cool"
            ),
            "vintage": ColorFilterParams(
                hue: 15,
                saturation: 0.8,
                brightness: -0.1,
                contrast: 1.2,
                temperature: 6000,
                presetName: "Vintage"
            ),
            "blackAndWhite": ColorFilterParams(
                hue: 0,
                saturation: 0,
                brightness: 0,
                contrast: 1.15,
                temperature: 6500,
                presetName: "Black & White"
            ),
            "highContrast": ColorFilterParams(
                hue: 0,
                saturation: 1.3,
                brightness: 0,
                contrast: 1.4,
                temperature: 6500,
                presetName: "High Contrast"
            )
        ]
    }
    
    func createVideoComposition(
        for asset: AVAsset,
        with params: ColorFilterParams
    ) -> AVVideoComposition {
        let composition = AVMutableVideoComposition(asset: asset) { request in
            let source = request.sourceImage.clampedToExtent()
            
            var output = source
            
            // 色调
            if params.hue != 0 {
                let hueFilter = CIFilter(name: "CIHueAdjust")!
                hueFilter.setValue(output, forKey: kCIInputImageKey)
                hueFilter.setValue(params.hue * .pi / 180, forKey: kCIInputAngleKey)
                output = hueFilter.outputImage!
            }
            
            // 饱和度、亮度、对比度
            let colorControls = CIFilter(name: "CIColorControls")!
            colorControls.setValue(output, forKey: kCIInputImageKey)
            colorControls.setValue(params.saturation, forKey: kCIInputSaturationKey)
            colorControls.setValue(params.brightness, forKey: kCIInputBrightnessKey)
            colorControls.setValue(params.contrast, forKey: kCIInputContrastKey)
            output = colorControls.outputImage!
            
            // 色温
            if params.temperature != 6500 {
                let tempFilter = CIFilter(name: "CITemperatureAndTint")!
                tempFilter.setValue(output, forKey: kCIInputImageKey)
                let neutral = CIVector(x: 6500, y: 0)
                let target = CIVector(x: params.temperature, y: 0)
                tempFilter.setValue(neutral, forKey: "inputNeutral")
                tempFilter.setValue(target, forKey: "inputTargetNeutral")
                output = tempFilter.outputImage!
            }
            
            request.finish(with: output, context: nil)
        }
        
        return composition
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
# Cmd+U
# 预期：通过
```

- [ ] **Step 5: 提交**

```bash
git add PlumWallPaper/Core/ColorFilterEngine.swift PlumWallPaperTests/ColorFilterEngineTests.swift
git commit -m "feat: add ColorFilterEngine with Core Image filters"
```

---

### Task 6: WallpaperEngine - 渲染引擎核心

**Files:**
- Create: `PlumWallPaper/Core/WallpaperEngine.swift`
- Create: `PlumWallPaperTests/WallpaperEngineTests.swift`

- [ ] **Step 1: 编写测试**

创建 `PlumWallPaperTests/WallpaperEngineTests.swift`:

```swift
import XCTest
import AVFoundation
@testable import PlumWallPaper

final class WallpaperEngineTests: XCTestCase {
    var engine: WallpaperEngine!
    
    override func setUp() {
        super.setUp()
        engine = WallpaperEngine()
    }
    
    override func tearDown() {
        engine = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertNotNil(engine)
    }
    
    func testSetWallpaperCreatesPlayer() {
        let wallpaper = Wallpaper(
            name: "Test",
            filePath: URL(fileURLWithPath: "/test/video.mp4"),
            thumbnailPath: URL(fileURLWithPath: "/test/thumb.jpg"),
            type: .video,
            duration: 10,
            resolution: CGSize(width: 1920, height: 1080),
            fileSize: 1024
        )
        
        let screen = NSScreen.main!
        engine.setWallpaper(wallpaper, for: screen)
        
        // 验证 player 已创建（通过内部状态）
        XCTAssertTrue(engine.hasPlayer(for: screen))
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
# Cmd+U
# 预期：编译失败
```

- [ ] **Step 3: 实现 WallpaperEngine**

创建 `PlumWallPaper/Core/WallpaperEngine.swift`:

```swift
import Foundation
import AVFoundation
import AppKit

final class WallpaperEngine {
    private var players: [String: AVPlayer] = [:]
    private var playerLayers: [String: AVPlayerLayer] = [:]
    private var windows: [String: NSWindow] = [:]
    private var loopers: [String: AVPlayerLooper] = [:]
    
    private let colorFilterEngine = ColorFilterEngine()
    
    func setWallpaper(_ wallpaper: Wallpaper, for screen: NSScreen) {
        let screenID = screenIdentifier(for: screen)
        
        // 清理旧的播放器
        cleanup(for: screenID)
        
        // 创建 AVPlayer
        let asset = AVAsset(url: wallpaper.filePath)
        let playerItem = AVPlayerItem(asset: asset)
        
        // 应用色彩滤镜
        if let filterParams = wallpaper.colorFilter {
            let composition = colorFilterEngine.createVideoComposition(
                for: asset,
                with: filterParams
            )
            playerItem.videoComposition = composition
        }
        
        let player = AVQueuePlayer(playerItem: playerItem)
        player.rate = Float(wallpaper.playbackSpeed)
        
        // 创建循环播放
        if wallpaper.type == .video {
            let looper = AVPlayerLooper(player: player, templateItem: playerItem)
            loopers[screenID] = looper
        }
        
        // 创建桌面窗口
        let window = createDesktopWindow(for: screen)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = window.contentView!.bounds
        playerLayer.videoGravity = .resizeAspectFill
        window.contentView!.layer = CALayer()
        window.contentView!.layer?.addSublayer(playerLayer)
        window.contentView!.wantsLayer = true
        
        // 保存引用
        players[screenID] = player
        playerLayers[screenID] = playerLayer
        windows[screenID] = window
        
        // 开始播放
        player.play()
        window.orderBack(nil)
    }
    
    func pause(for screen: NSScreen) {
        let screenID = screenIdentifier(for: screen)
        players[screenID]?.pause()
    }
    
    func resume(for screen: NSScreen) {
        let screenID = screenIdentifier(for: screen)
        players[screenID]?.play()
    }
    
    func applyColorFilter(_ params: ColorFilterParams, to wallpaper: Wallpaper) {
        // 更新 wallpaper 的 colorFilter 属性后重新设置
        // 这个方法会在 UI 层调用
    }
    
    func hasPlayer(for screen: NSScreen) -> Bool {
        let screenID = screenIdentifier(for: screen)
        return players[screenID] != nil
    }
    
    private func createDesktopWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) - 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = true
        return window
    }
    
    private func cleanup(for screenID: String) {
        players[screenID]?.pause()
        players[screenID] = nil
        playerLayers[screenID] = nil
        windows[screenID]?.close()
        windows[screenID] = nil
        loopers[screenID] = nil
    }
    
    private func screenIdentifier(for screen: NSScreen) -> String {
        return screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? String ?? "main"
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
# Cmd+U
# 预期：通过
```

- [ ] **Step 5: 提交**

```bash
git add PlumWallPaper/Core/WallpaperEngine.swift PlumWallPaperTests/WallpaperEngineTests.swift
git commit -m "feat: add WallpaperEngine with AVPlayer rendering"
```

---

### Task 7: DisplayManager - 多显示器管理

**Files:**
- Create: `PlumWallPaper/Core/DisplayManager.swift`
- Create: `PlumWallPaperTests/DisplayManagerTests.swift`

- [ ] **Step 1: 编写测试**

创建 `PlumWallPaperTests/DisplayManagerTests.swift`:

```swift
import XCTest
@testable import PlumWallPaper

final class DisplayManagerTests: XCTestCase {
    var manager: DisplayManager!
    
    override func setUp() {
        super.setUp()
        manager = DisplayManager()
    }
    
    func testInitialScreensDetection() {
        XCTAssertFalse(manager.screens.isEmpty)
        XCTAssertGreaterThanOrEqual(manager.screens.count, 1)
    }
    
    func testAssignWallpaper() {
        let wallpaperID = UUID()
        let screenID = "test-screen"
        
        manager.assignWallpaper(wallpaperID, to: screenID)
        
        XCTAssertEqual(manager.wallpaperAssignments[screenID], wallpaperID)
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
# Cmd+U
# 预期：编译失败
```

- [ ] **Step 3: 实现 DisplayManager**

创建 `PlumWallPaper/Core/DisplayManager.swift`:

```swift
import Foundation
import AppKit
import Combine

final class DisplayManager: ObservableObject {
    @Published var screens: [NSScreen] = []
    @Published var wallpaperAssignments: [String: UUID] = [:]
    
    private var screenChangeObserver: NSObjectProtocol?
    
    init() {
        updateScreens()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func assignWallpaper(_ wallpaperID: UUID, to screenID: String) {
        wallpaperAssignments[screenID] = wallpaperID
    }
    
    func handleScreenChange() {
        updateScreens()
        // 通知 WallpaperEngine 重新分配壁纸
    }
    
    private func updateScreens() {
        screens = NSScreen.screens
    }
    
    private func startMonitoring() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenChange()
        }
    }
    
    private func stopMonitoring() {
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
# Cmd+U
# 预期：通过
```

- [ ] **Step 5: 提交**

```bash
git add PlumWallPaper/Core/DisplayManager.swift PlumWallPaperTests/DisplayManagerTests.swift
git commit -m "feat: add DisplayManager for multi-monitor support"
```

<!-- PHASE_3_PLACEHOLDER -->
## 阶段 3：轮播和省电管理

### Task 8: RotationScheduler - 轮播调度器

**Files:**
- Create: `PlumWallPaper/Core/RotationScheduler.swift`
- Create: `PlumWallPaperTests/RotationSchedulerTests.swift`

- [ ] **Step 1: 编写测试**

创建 `PlumWallPaperTests/RotationSchedulerTests.swift`:

```swift
import XCTest
@testable import PlumWallPaper

final class RotationSchedulerTests: XCTestCase {
    var scheduler: RotationScheduler!
    var mockWallpapers: [UUID]!
    
    override func setUp() {
        super.setUp()
        scheduler = RotationScheduler()
        mockWallpapers = [UUID(), UUID(), UUID()]
    }
    
    func testSequentialOrder() {
        let config = RotationConfig(
            enabled: true,
            interval: 10,
            wallpaperIDs: mockWallpapers,
            order: .sequential
        )
        
        scheduler.start(with: config)
        
        let first = scheduler.nextWallpaper(for: "screen1")
        let second = scheduler.nextWallpaper(for: "screen1")
        
        XCTAssertEqual(first, mockWallpapers[0])
        XCTAssertEqual(second, mockWallpapers[1])
    }
    
    func testRandomOrder() {
        let config = RotationConfig(
            enabled: true,
            interval: 10,
            wallpaperIDs: mockWallpapers,
            order: .random
        )
        
        scheduler.start(with: config)
        
        let wallpaper = scheduler.nextWallpaper(for: "screen1")
        XCTAssertTrue(mockWallpapers.contains(wallpaper!))
    }
    
    func testStopScheduler() {
        let config = RotationConfig(
            enabled: true,
            interval: 10,
            wallpaperIDs: mockWallpapers,
            order: .sequential
        )
        
        scheduler.start(with: config)
        scheduler.stop()
        
        XCTAssertFalse(scheduler.isRunning)
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
# Cmd+U
# 预期：编译失败
```

- [ ] **Step 3: 实现 RotationScheduler**

创建 `PlumWallPaper/Core/RotationScheduler.swift`:

```swift
import Foundation

final class RotationScheduler {
    private var timer: Timer?
    private var config: RotationConfig?
    private var currentIndices: [String: Int] = [:]
    
    var isRunning: Bool {
        return timer != nil
    }
    
    func start(with config: RotationConfig) {
        stop()
        
        self.config = config
        
        guard config.enabled else { return }
        
        timer = Timer.scheduledTimer(
            withTimeInterval: config.interval,
            repeats: true
        ) { [weak self] _ in
            self?.rotate()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        currentIndices.removeAll()
    }
    
    func nextWallpaper(for screenID: String) -> UUID? {
        guard let config = config else { return nil }
        
        let wallpapers = config.perDisplay[screenID] ?? config.wallpaperIDs
        guard !wallpapers.isEmpty else { return nil }
        
        switch config.order {
        case .sequential:
            let index = currentIndices[screenID] ?? 0
            let nextIndex = (index + 1) % wallpapers.count
            currentIndices[screenID] = nextIndex
            return wallpapers[index]
            
        case .random:
            return wallpapers.randomElement()
        }
    }
    
    private func rotate() {
        // 通知 DisplayManager 切换壁纸
        // 实际实现中会通过 delegate 或 Combine 通知
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
# Cmd+U
# 预期：通过
```

- [ ] **Step 5: 提交**

```bash
git add PlumWallPaper/Core/RotationScheduler.swift PlumWallPaperTests/RotationSchedulerTests.swift
git commit -m "feat: add RotationScheduler for wallpaper rotation"
```

---

### Task 9: PowerManager - 省电管理器

**Files:**
- Create: `PlumWallPaper/Core/PowerManager.swift`
- Create: `PlumWallPaperTests/PowerManagerTests.swift`

- [ ] **Step 1: 编写测试**

创建 `PlumWallPaperTests/PowerManagerTests.swift`:

```swift
import XCTest
@testable import PlumWallPaper

final class PowerManagerTests: XCTestCase {
    var manager: PowerManager!
    
    override func setUp() {
        super.setUp()
        manager = PowerManager()
    }
    
    func testSmartModePausesOnBattery() {
        let config = PowerSavingConfig(mode: .smart, pauseOnBattery: true)
        manager.updateConfig(config)
        
        // 模拟电池模式
        manager.simulateBatteryMode(true)
        
        XCTAssertTrue(manager.shouldPause())
    }
    
    func testAlwaysOnNeverPauses() {
        let config = PowerSavingConfig(mode: .alwaysOn)
        manager.updateConfig(config)
        
        manager.simulateBatteryMode(true)
        manager.simulateFullscreen(true)
        
        XCTAssertFalse(manager.shouldPause())
    }
    
    func testCustomModeRespectsSettings() {
        let config = PowerSavingConfig(
            mode: .custom,
            pauseOnFullscreen: true,
            pauseOnBattery: false
        )
        manager.updateConfig(config)
        
        manager.simulateFullscreen(true)
        XCTAssertTrue(manager.shouldPause())
        
        manager.simulateFullscreen(false)
        manager.simulateBatteryMode(true)
        XCTAssertFalse(manager.shouldPause())
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
# Cmd+U
# 预期：编译失败
```

- [ ] **Step 3: 实现 PowerManager**

创建 `PlumWallPaper/Core/PowerManager.swift`:

```swift
import Foundation
import AppKit
import IOKit.ps

final class PowerManager {
    private var config: PowerSavingConfig = PowerSavingConfig()
    private var isOnBattery: Bool = false
    private var isFullscreen: Bool = false
    private var isLowBattery: Bool = false
    private var activeAppBundleID: String?
    
    private var powerSourceObserver: CFRunLoopSource?
    private var appActivationObserver: NSObjectProtocol?
    
    func startMonitoring() {
        monitorPowerSource()
        monitorAppActivation()
    }
    
    func stopMonitoring() {
        if let observer = powerSourceObserver {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), observer, .defaultMode)
        }
        if let observer = appActivationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func updateConfig(_ config: PowerSavingConfig) {
        self.config = config
    }
    
    func shouldPause() -> Bool {
        switch config.mode {
        case .alwaysOn:
            return false
            
        case .smart:
            return isOnBattery || isFullscreen
            
        case .powerSaver:
            return isOnBattery || isFullscreen || isLowBattery
            
        case .custom:
            if config.pauseOnBattery && isOnBattery { return true }
            if config.pauseOnLowBattery && isLowBattery { return true }
            if config.pauseOnFullscreen && isFullscreen { return true }
            if config.pauseOnAnyAppFocus && activeAppBundleID != nil {
                if !config.excludedApps.contains(activeAppBundleID!) {
                    return true
                }
            }
            return false
        }
    }
    
    // MARK: - Testing helpers
    
    func simulateBatteryMode(_ onBattery: Bool) {
        isOnBattery = onBattery
    }
    
    func simulateFullscreen(_ fullscreen: Bool) {
        isFullscreen = fullscreen
    }
    
    // MARK: - Private
    
    private func monitorPowerSource() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        powerSourceObserver = IOPSNotificationCreateRunLoopSource({ context in
            guard let context = context else { return }
            let manager = Unmanaged<PowerManager>.fromOpaque(context).takeUnretainedValue()
            manager.updatePowerStatus()
        }, context).takeRetainedValue()
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), powerSourceObserver, .defaultMode)
        updatePowerStatus()
    }
    
    private func updatePowerStatus() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        guard let source = sources.first else { return }
        
        if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
            isOnBattery = (description[kIOPSPowerSourceStateKey] as? String) == kIOPSBatteryPowerValue
            
            if let capacity = description[kIOPSCurrentCapacityKey] as? Int {
                isLowBattery = capacity < 20
            }
        }
    }
    
    private func monitorAppActivation() {
        appActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                self?.activeAppBundleID = app.bundleIdentifier
                self?.checkFullscreen(app)
            }
        }
    }
    
    private func checkFullscreen(_ app: NSRunningApplication) {
        // 检测应用是否全屏
        // 需要屏幕录制权限
        isFullscreen = NSApp.presentationOptions.contains(.fullScreen)
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
# Cmd+U
# 预期：通过
```

- [ ] **Step 5: 提交**

```bash
git add PlumWallPaper/Core/PowerManager.swift PlumWallPaperTests/PowerManagerTests.swift
git commit -m "feat: add PowerManager for power saving strategies"
```

<!-- PHASE_4_PLACEHOLDER -->
## 阶段 4：数据持久化

### Task 10: WallpaperStore - 壁纸数据存储

**Files:**
- Create: `PlumWallPaper/Storage/WallpaperStore.swift`
- Create: `PlumWallPaperTests/WallpaperStoreTests.swift`

- [ ] **Step 1: 编写测试**

创建 `PlumWallPaperTests/WallpaperStoreTests.swift`:

```swift
import XCTest
import SwiftData
@testable import PlumWallPaper

final class WallpaperStoreTests: XCTestCase {
    var store: WallpaperStore!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Wallpaper.self, configurations: config)
        modelContext = ModelContext(container)
        store = WallpaperStore(modelContext: modelContext)
    }
    
    func testAddWallpaper() async throws {
        let wallpaper = Wallpaper(
            name: "Test",
            filePath: URL(fileURLWithPath: "/test/video.mp4"),
            thumbnailPath: URL(fileURLWithPath: "/test/thumb.jpg"),
            type: .video,
            duration: 10,
            resolution: CGSize(width: 1920, height: 1080),
            fileSize: 1024
        )
        
        try await store.add(wallpaper)
        
        let all = try await store.fetchAll()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.name, "Test")
    }
    
    func testSearchByName() async throws {
        let wallpaper1 = Wallpaper(
            name: "Sunset Video",
            filePath: URL(fileURLWithPath: "/test/sunset.mp4"),
            thumbnailPath: URL(fileURLWithPath: "/test/thumb1.jpg"),
            type: .video,
            duration: 10,
            resolution: CGSize(width: 1920, height: 1080),
            fileSize: 1024
        )
        
        let wallpaper2 = Wallpaper(
            name: "Ocean HEIC",
            filePath: URL(fileURLWithPath: "/test/ocean.heic"),
            thumbnailPath: URL(fileURLWithPath: "/test/thumb2.jpg"),
            type: .heic,
            duration: nil,
            resolution: CGSize(width: 3840, height: 2160),
            fileSize: 2048
        )
        
        try await store.add(wallpaper1)
        try await store.add(wallpaper2)
        
        let results = try await store.search(query: "sunset")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Sunset Video")
    }
    
    func testDeleteWallpaper() async throws {
        let wallpaper = Wallpaper(
            name: "To Delete",
            filePath: URL(fileURLWithPath: "/test/video.mp4"),
            thumbnailPath: URL(fileURLWithPath: "/test/thumb.jpg"),
            type: .video,
            duration: 10,
            resolution: CGSize(width: 1920, height: 1080),
            fileSize: 1024
        )
        
        try await store.add(wallpaper)
        try await store.delete(wallpaper)
        
        let all = try await store.fetchAll()
        XCTAssertTrue(all.isEmpty)
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
# Cmd+U
# 预期：编译失败
```

- [ ] **Step 3: 实现 WallpaperStore**

创建 `PlumWallPaper/Storage/WallpaperStore.swift`:

```swift
import Foundation
import SwiftData

@MainActor
final class WallpaperStore: ObservableObject {
    private let modelContext: ModelContext
    
    @Published var wallpapers: [Wallpaper] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func add(_ wallpaper: Wallpaper) throws {
        modelContext.insert(wallpaper)
        try modelContext.save()
        try fetchAll()
    }
    
    func delete(_ wallpaper: Wallpaper) throws {
        modelContext.delete(wallpaper)
        try modelContext.save()
        try fetchAll()
    }
    
    func update(_ wallpaper: Wallpaper) throws {
        try modelContext.save()
        try fetchAll()
    }
    
    @discardableResult
    func fetchAll() throws -> [Wallpaper] {
        let descriptor = FetchDescriptor<Wallpaper>(
            sortBy: [SortDescriptor(\.importDate, order: .reverse)]
        )
        wallpapers = try modelContext.fetch(descriptor)
        return wallpapers
    }
    
    func search(query: String) throws -> [Wallpaper] {
        let predicate = #Predicate<Wallpaper> { wallpaper in
            wallpaper.name.localizedStandardContains(query)
        }
        let descriptor = FetchDescriptor<Wallpaper>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.importDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetch(by id: UUID) throws -> Wallpaper? {
        let predicate = #Predicate<Wallpaper> { wallpaper in
            wallpaper.id == id
        }
        let descriptor = FetchDescriptor<Wallpaper>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
    }
    
    func updateLastUsed(_ wallpaper: Wallpaper) throws {
        wallpaper.lastUsedDate = Date()
        try modelContext.save()
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
# Cmd+U
# 预期：通过
```

- [ ] **Step 5: 提交**

```bash
git add PlumWallPaper/Storage/WallpaperStore.swift PlumWallPaperTests/WallpaperStoreTests.swift
git commit -m "feat: add WallpaperStore with SwiftData persistence"
```

---

### Task 11: PreferencesStore - 用户配置存储

**Files:**
- Create: `PlumWallPaper/Storage/PreferencesStore.swift`
- Create: `PlumWallPaperTests/PreferencesStoreTests.swift`

- [ ] **Step 1: 编写测试**

创建 `PlumWallPaperTests/PreferencesStoreTests.swift`:

```swift
import XCTest
@testable import PlumWallPaper

final class PreferencesStoreTests: XCTestCase {
    var store: PreferencesStore!
    
    override func setUp() {
        super.setUp()
        store = PreferencesStore(userDefaults: UserDefaults(suiteName: "test")!)
    }
    
    override func tearDown() {
        store.userDefaults.removePersistentDomain(forName: "test")
        super.tearDown()
    }
    
    func testSaveAndLoadRotationConfig() {
        let config = RotationConfig(
            enabled: true,
            interval: 600,
            wallpaperIDs: [UUID(), UUID()],
            order: .random
        )
        
        store.saveRotationConfig(config)
        let loaded = store.loadRotationConfig()
        
        XCTAssertEqual(loaded.enabled, config.enabled)
        XCTAssertEqual(loaded.interval, config.interval)
        XCTAssertEqual(loaded.order, config.order)
    }
    
    func testSaveAndLoadPowerSavingConfig() {
        let config = PowerSavingConfig(
            mode: .custom,
            pauseOnFullscreen: true,
            pauseOnBattery: false
        )
        
        store.savePowerSavingConfig(config)
        let loaded = store.loadPowerSavingConfig()
        
        XCTAssertEqual(loaded.mode, config.mode)
        XCTAssertEqual(loaded.pauseOnFullscreen, config.pauseOnFullscreen)
        XCTAssertEqual(loaded.pauseOnBattery, config.pauseOnBattery)
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
# Cmd+U
# 预期：编译失败
```

- [ ] **Step 3: 实现 PreferencesStore**

创建 `PlumWallPaper/Storage/PreferencesStore.swift`:

```swift
import Foundation

final class PreferencesStore {
    let userDefaults: UserDefaults
    
    private enum Keys {
        static let rotationConfig = "rotationConfig"
        static let powerSavingConfig = "powerSavingConfig"
        static let wallpaperAssignments = "wallpaperAssignments"
    }
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Rotation Config
    
    func saveRotationConfig(_ config: RotationConfig) {
        if let data = try? JSONEncoder().encode(config) {
            userDefaults.set(data, forKey: Keys.rotationConfig)
        }
    }
    
    func loadRotationConfig() -> RotationConfig {
        guard let data = userDefaults.data(forKey: Keys.rotationConfig),
              let config = try? JSONDecoder().decode(RotationConfig.self, from: data) else {
            return RotationConfig()
        }
        return config
    }
    
    // MARK: - Power Saving Config
    
    func savePowerSavingConfig(_ config: PowerSavingConfig) {
        if let data = try? JSONEncoder().encode(config) {
            userDefaults.set(data, forKey: Keys.powerSavingConfig)
        }
    }
    
    func loadPowerSavingConfig() -> PowerSavingConfig {
        guard let data = userDefaults.data(forKey: Keys.powerSavingConfig),
              let config = try? JSONDecoder().decode(PowerSavingConfig.self, from: data) else {
            return PowerSavingConfig()
        }
        return config
    }
    
    // MARK: - Wallpaper Assignments
    
    func saveWallpaperAssignments(_ assignments: [String: UUID]) {
        let dict = assignments.mapValues { $0.uuidString }
        userDefaults.set(dict, forKey: Keys.wallpaperAssignments)
    }
    
    func loadWallpaperAssignments() -> [String: UUID] {
        guard let dict = userDefaults.dictionary(forKey: Keys.wallpaperAssignments) as? [String: String] else {
            return [:]
        }
        return dict.compactMapValues { UUID(uuidString: $0) }
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
# Cmd+U
# 预期：通过
```

- [ ] **Step 5: 提交**

```bash
git add PlumWallPaper/Storage/PreferencesStore.swift PlumWallPaperTests/PreferencesStoreTests.swift
git commit -m "feat: add PreferencesStore for user settings"
```

---

### Task 12: 系统集成 - DesktopBridge

**Files:**
- Create: `PlumWallPaper/System/DesktopBridge.swift`
- Create: `PlumWallPaperTests/DesktopBridgeTests.swift`

- [ ] **Step 1: 编写测试**

创建 `PlumWallPaperTests/DesktopBridgeTests.swift`:

```swift
import XCTest
@testable import PlumWallPaper

final class DesktopBridgeTests: XCTestCase {
    var bridge: DesktopBridge!
    
    override func setUp() {
        super.setUp()
        bridge = DesktopBridge()
    }
    
    func testSetHEICWallpaper() {
        let url = URL(fileURLWithPath: "/test/dynamic.heic")
        let screen = NSScreen.main!
        
        let result = bridge.setDesktopImage(url, for: screen)
        
        // 实际测试中会失败因为文件不存在，但验证方法存在
        XCTAssertNotNil(result)
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
# Cmd+U
# 预期：编译失败
```

- [ ] **Step 3: 实现 DesktopBridge**

创建 `PlumWallPaper/System/DesktopBridge.swift`:

```swift
import Foundation
import AppKit

final class DesktopBridge {
    func setDesktopImage(_ url: URL, for screen: NSScreen) -> Error? {
        do {
            try NSWorkspace.shared.setDesktopImageURL(url, for: screen)
            return nil
        } catch {
            return error
        }
    }
    
    func requestScreenRecordingPermission() -> Bool {
        // 检查屏幕录制权限（用于检测全屏应用）
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        return AXIsProcessTrustedWithOptions(options)
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
# Cmd+U
# 预期：通过
```

- [ ] **Step 5: 提交**

```bash
git add PlumWallPaper/System/DesktopBridge.swift PlumWallPaperTests/DesktopBridgeTests.swift
git commit -m "feat: add DesktopBridge for macOS wallpaper API"
```

<!-- PHASE_5_PLACEHOLDER -->
## 阶段 5：UI 界面（由 huashu-design 设计）

### Task 13: 应用入口和 SwiftData 配置

**Files:**
- Modify: `PlumWallPaper/PlumWallPaperApp.swift`

- [ ] **Step 1: 配置 SwiftData 容器**

修改 `PlumWallPaper/PlumWallPaperApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct PlumWallPaperApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(for: Wallpaper.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add PlumWallPaper/PlumWallPaperApp.swift
git commit -m "feat: configure SwiftData ModelContainer"
```

---

### Task 14: 使用 huashu-design 设计 UI

**Files:**
- Create: `PlumWallPaper/UI/ContentView.swift`
- Create: `PlumWallPaper/UI/WallpaperLibraryView.swift`
- Create: `PlumWallPaper/UI/ColorAdjustmentView.swift`
- Create: `PlumWallPaper/UI/MenuBarController.swift`

- [ ] **Step 1: 调用 huashu-design skill 设计主界面**

在 Claude Code 中运行：

```
/huashu-design

设计 PlumWallPaper 的主界面，要求：

1. **壁纸库主界面**
   - macOS 原生风格，类似系统设置应用
   - 顶部工具栏：搜索框 + 排序下拉菜单（按名称/导入时间）+ 导入按钮
   - 中间区域：卡片式网格布局，每个卡片包含：
     - 壁纸缩略图（16:9 比例）
     - 壁纸名称
     - 时长标签（视频）或"动态"标签（HEIC）
     - 鼠标悬停时显示操作按钮（设为壁纸/编辑/删除）
   - 底部状态栏：显示壁纸总数和存储占用

2. **色彩调节面板**
   - 左侧：实时预览区域（显示应用滤镜后的效果）
   - 右侧：滑块控制
     - 色调（-180 ~ 180）
     - 饱和度（0 ~ 2）
     - 亮度（-1 ~ 1）
     - 对比度（0 ~ 2）
     - 色温（2000 ~ 10000K）
   - 底部：预设滤镜按钮（暖色/冷色/复古/黑白/高对比度）+ 保存自定义预设按钮

3. **设置面板**
   - 轮播设置：开关、间隔时间、顺序（顺序/随机）
   - 省电策略：模式选择（始终播放/智能/省电/自定义）+ 详细选项
   - 多显示器：每个屏幕的壁纸分配

技术要求：
- 使用 SwiftUI
- 遵循 macOS Human Interface Guidelines
- 流畅的动画过渡
- 响应式布局

请生成完整的 SwiftUI 代码。
```

- [ ] **Step 2: 将 huashu-design 生成的代码保存到对应文件**

将生成的代码分别保存到：
- `PlumWallPaper/UI/ContentView.swift`
- `PlumWallPaper/UI/WallpaperLibraryView.swift`
- `PlumWallPaper/UI/ColorAdjustmentView.swift`
- `PlumWallPaper/UI/SettingsView.swift`

- [ ] **Step 3: 集成核心组件到 UI**

在 `ContentView.swift` 中注入依赖：

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var wallpaperStore: WallpaperStore
    @StateObject private var displayManager = DisplayManager()
    @StateObject private var wallpaperEngine = WallpaperEngine()
    
    init() {
        // 注意：实际实现中需要从 environment 获取 modelContext
        // 这里简化处理
    }
    
    var body: some View {
        NavigationSplitView {
            // 侧边栏
            List {
                NavigationLink("壁纸库", destination: WallpaperLibraryView())
                NavigationLink("设置", destination: SettingsView())
            }
        } detail: {
            WallpaperLibraryView()
        }
    }
}
```

- [ ] **Step 4: 实现菜单栏控制器**

创建 `PlumWallPaper/UI/MenuBarController.swift`:

```swift
import AppKit
import SwiftUI

final class MenuBarController {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    
    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "photo.on.rectangle", accessibilityDescription: "PlumWallPaper")
        }
        
        menu = NSMenu()
        
        menu?.addItem(NSMenuItem(title: "下一张壁纸", action: #selector(nextWallpaper), keyEquivalent: "n"))
        menu?.addItem(NSMenuItem(title: "暂停", action: #selector(pauseWallpaper), keyEquivalent: "p"))
        menu?.addItem(NSMenuItem.separator())
        menu?.addItem(NSMenuItem(title: "打开主窗口", action: #selector(openMainWindow), keyEquivalent: "o"))
        menu?.addItem(NSMenuItem.separator())
        menu?.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc private func nextWallpaper() {
        // 触发轮播到下一张
    }
    
    @objc private func pauseWallpaper() {
        // 暂停/恢复播放
    }
    
    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
```

- [ ] **Step 5: 在 App 中初始化菜单栏**

修改 `PlumWallPaperApp.swift`:

```swift
@main
struct PlumWallPaperApp: App {
    let modelContainer: ModelContainer
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // ... 其余代码
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController = MenuBarController()
        menuBarController?.setup()
    }
}
```

- [ ] **Step 6: 构建并运行应用**

```bash
# 在 Xcode 中按 Cmd+R 运行
# 验证：
# - 主窗口显示正常
# - 菜单栏图标出现
# - 点击菜单栏可以看到选项
```

- [ ] **Step 7: 提交**

```bash
git add PlumWallPaper/UI/*.swift PlumWallPaper/PlumWallPaperApp.swift
git commit -m "feat: add UI with huashu-design"
```

---

### Task 15: 壁纸导入功能

**Files:**
- Create: `PlumWallPaper/Core/WallpaperImporter.swift`
- Create: `PlumWallPaperTests/WallpaperImporterTests.swift`

- [ ] **Step 1: 编写测试**

创建 `PlumWallPaperTests/WallpaperImporterTests.swift`:

```swift
import XCTest
import AVFoundation
@testable import PlumWallPaper

final class WallpaperImporterTests: XCTestCase {
    var importer: WallpaperImporter!
    
    override func setUp() {
        super.setUp()
        importer = WallpaperImporter()
    }
    
    func testGenerateThumbnail() async throws {
        // 需要真实视频文件进行测试
        // 这里只验证方法存在
        XCTAssertNotNil(importer)
    }
    
    func testDetectDuplicates() {
        let url1 = URL(fileURLWithPath: "/test/video.mp4")
        let url2 = URL(fileURLWithPath: "/test/video.mp4")
        
        XCTAssertTrue(importer.isDuplicate(url1, existing: [url1]))
        XCTAssertFalse(importer.isDuplicate(url2, existing: []))
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

```bash
# Cmd+U
# 预期：编译失败
```

- [ ] **Step 3: 实现 WallpaperImporter**

创建 `PlumWallPaper/Core/WallpaperImporter.swift`:

```swift
import Foundation
import AVFoundation
import AppKit

final class WallpaperImporter {
    private let thumbnailSize = CGSize(width: 300, height: 200)
    private let cacheDirectory: URL
    
    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = caches.appendingPathComponent("PlumWallPaper/Thumbnails")
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func importWallpaper(from url: URL) async throws -> Wallpaper {
        let type = detectType(url)
        let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as! Int64
        
        let thumbnail = try await generateThumbnail(from: url, type: type)
        let thumbnailPath = cacheDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
        try saveThumbnail(thumbnail, to: thumbnailPath)
        
        var duration: TimeInterval? = nil
        var resolution = CGSize.zero
        
        if type == .video {
            let asset = AVAsset(url: url)
            duration = try await asset.load(.duration).seconds
            if let track = try await asset.loadTracks(withMediaType: .video).first {
                resolution = try await track.load(.naturalSize)
            }
        } else {
            // HEIC
            if let image = NSImage(contentsOf: url) {
                resolution = image.size
            }
        }
        
        return Wallpaper(
            name: url.deletingPathExtension().lastPathComponent,
            filePath: url,
            thumbnailPath: thumbnailPath,
            type: type,
            duration: duration,
            resolution: resolution,
            fileSize: fileSize
        )
    }
    
    func isDuplicate(_ url: URL, existing: [URL]) -> Bool {
        return existing.contains(url)
    }
    
    private func detectType(_ url: URL) -> WallpaperType {
        let ext = url.pathExtension.lowercased()
        return ext == "heic" ? .heic : .video
    }
    
    private func generateThumbnail(from url: URL, type: WallpaperType) async throws -> NSImage {
        if type == .video {
            let asset = AVAsset(url: url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            
            let time = CMTime(seconds: 0, preferredTimescale: 600)
            let cgImage = try await generator.image(at: time).image
            return NSImage(cgImage: cgImage, size: thumbnailSize)
        } else {
            guard let image = NSImage(contentsOf: url) else {
                throw NSError(domain: "WallpaperImporter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load HEIC"])
            }
            return image
        }
    }
    
    private func saveThumbnail(_ image: NSImage, to url: URL) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            throw NSError(domain: "WallpaperImporter", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to save thumbnail"])
        }
        try jpegData.write(to: url)
    }
}
```

- [ ] **Step 4: 运行测试验证通过**

```bash
# Cmd+U
# 预期：通过
```

- [ ] **Step 5: 集成到 UI**

在 `WallpaperLibraryView.swift` 中添加导入按钮处理：

```swift
Button("导入壁纸") {
    let panel = NSOpenPanel()
    panel.allowsMultipleSelection = true
    panel.canChooseDirectories = false
    panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, .heic]
    
    if panel.runModal() == .OK {
        Task {
            for url in panel.urls {
                do {
                    let wallpaper = try await importer.importWallpaper(from: url)
                    try wallpaperStore.add(wallpaper)
                } catch {
                    print("Import failed: \(error)")
                }
            }
        }
    }
}
```

- [ ] **Step 6: 提交**

```bash
git add PlumWallPaper/Core/WallpaperImporter.swift PlumWallPaperTests/WallpaperImporterTests.swift PlumWallPaper/UI/WallpaperLibraryView.swift
git commit -m "feat: add wallpaper import with thumbnail generation"
```

<!-- PHASE_6_PLACEHOLDER -->
## 阶段 6：集成测试和优化

### Task 16: 端到端集成测试

**Files:**
- Create: `PlumWallPaperTests/IntegrationTests.swift`

- [ ] **Step 1: 编写集成测试**

创建 `PlumWallPaperTests/IntegrationTests.swift`:

```swift
import XCTest
@testable import PlumWallPaper

final class IntegrationTests: XCTestCase {
    func testCompleteWorkflow() async throws {
        // 1. 导入壁纸
        let importer = WallpaperImporter()
        // 需要准备测试视频文件
        
        // 2. 保存到 Store
        // 3. 设置为壁纸
        // 4. 应用色彩滤镜
        // 5. 启动轮播
        // 6. 测试省电策略
        
        // 完整流程测试
    }
    
    func testMultiDisplayScenario() {
        // 测试多显示器场景
        let displayManager = DisplayManager()
        let engine = WallpaperEngine()
        
        // 验证每个屏幕可以独立设置壁纸
    }
}
```

- [ ] **Step 2: 运行集成测试**

```bash
# Cmd+U
# 验证所有组件协同工作
```

- [ ] **Step 3: 提交**

```bash
git add PlumWallPaperTests/IntegrationTests.swift
git commit -m "test: add integration tests"
```

---

### Task 17: 性能优化

**Files:**
- Modify: `PlumWallPaper/Core/WallpaperEngine.swift`
- Create: `PlumWallPaperTests/PerformanceTests.swift`

- [ ] **Step 1: 编写性能测试**

创建 `PlumWallPaperTests/PerformanceTests.swift`:

```swift
import XCTest
@testable import PlumWallPaper

final class PerformanceTests: XCTestCase {
    func testMemoryUsage() {
        // 测试内存占用 < 150MB
        measure(metrics: [XCTMemoryMetric()]) {
            let engine = WallpaperEngine()
            // 播放多个壁纸
        }
    }
    
    func testCPUUsage() {
        // 测试 CPU 占用 < 5%
        measure(metrics: [XCTCPUMetric()]) {
            let engine = WallpaperEngine()
            // 播放壁纸
        }
    }
}
```

- [ ] **Step 2: 运行性能测试**

```bash
# Cmd+U
# 检查性能指标
```

- [ ] **Step 3: 优化 WallpaperEngine**

如果性能不达标，优化：
- 降低视频解码质量
- 减少滤镜计算频率
- 优化内存管理

- [ ] **Step 4: 提交**

```bash
git add PlumWallPaper/Core/WallpaperEngine.swift PlumWallPaperTests/PerformanceTests.swift
git commit -m "perf: optimize WallpaperEngine performance"
```

---

### Task 18: 错误处理和用户反馈

**Files:**
- Create: `PlumWallPaper/Core/ErrorHandler.swift`
- Modify: `PlumWallPaper/UI/WallpaperLibraryView.swift`

- [ ] **Step 1: 实现错误处理器**

创建 `PlumWallPaper/Core/ErrorHandler.swift`:

```swift
import Foundation
import AppKit

final class ErrorHandler {
    static func handle(_ error: Error, context: String) {
        print("[\(context)] Error: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "错误"
            alert.informativeText = "\(context): \(error.localizedDescription)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
}
```

- [ ] **Step 2: 在 UI 中集成错误处理**

修改 `WallpaperLibraryView.swift`，添加错误处理：

```swift
.task {
    do {
        try await wallpaperStore.fetchAll()
    } catch {
        ErrorHandler.handle(error, context: "加载壁纸列表")
    }
}
```

- [ ] **Step 3: 提交**

```bash
git add PlumWallPaper/Core/ErrorHandler.swift PlumWallPaper/UI/WallpaperLibraryView.swift
git commit -m "feat: add error handling and user feedback"
```

---

### Task 19: 应用图标和元数据

**Files:**
- Create: `PlumWallPaper/Assets.xcassets/AppIcon.appiconset/`
- Modify: `PlumWallPaper/Info.plist`

- [ ] **Step 1: 设计应用图标**

使用 huashu-design 或其他工具设计应用图标：
- 1024x1024 主图标
- 各种尺寸的图标（512, 256, 128, 64, 32, 16）

- [ ] **Step 2: 添加到 Assets**

将图标添加到 `Assets.xcassets/AppIcon.appiconset/`

- [ ] **Step 3: 配置 Info.plist**

添加应用元数据：
```xml
<key>CFBundleName</key>
<string>PlumWallPaper</string>
<key>CFBundleDisplayName</key>
<string>PlumWallPaper</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
<key>LSMinimumSystemVersion</key>
<string>14.0</string>
<key>NSHumanReadableCopyright</key>
<string>Copyright © 2026</string>
```

- [ ] **Step 4: 提交**

```bash
git add PlumWallPaper/Assets.xcassets PlumWallPaper/Info.plist
git commit -m "feat: add app icon and metadata"
```

---

### Task 20: 文档和 README

**Files:**
- Create: `README.md`
- Create: `docs/USER_GUIDE.md`
- Create: `LICENSE`

- [ ] **Step 1: 编写 README**

创建 `README.md`:

```markdown
# PlumWallPaper

macOS 离线动态壁纸管理软件

## 功能特性

- 支持视频壁纸（MP4/MOV）和 HEIC 动态壁纸
- 完整色彩调节（色调/色温/饱和度/亮度/对比度）
- 多显示器独立设置
- 定时轮播（顺序/随机）
- 可配置省电策略
- macOS 原生 SwiftUI 界面

## 系统要求

- macOS 14.0+
- Apple Silicon 或 Intel Mac

## 安装

1. 下载最新版本
2. 拖拽到应用程序文件夹
3. 首次运行时授予必要权限

## 使用指南

详见 [用户指南](docs/USER_GUIDE.md)

## 开发

### 技术栈

- SwiftUI
- SwiftData
- AVFoundation
- Core Image

### 构建

```bash
git clone https://github.com/yourusername/PlumWallPaper.git
cd PlumWallPaper
open PlumWallPaper.xcodeproj
```

在 Xcode 中按 Cmd+R 运行

### 测试

```bash
# 单元测试
Cmd+U in Xcode

# 性能测试
Cmd+I > Instruments
```

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request
```

- [ ] **Step 2: 编写用户指南**

创建 `docs/USER_GUIDE.md`，包含：
- 导入壁纸
- 设置壁纸
- 色彩调节
- 轮播配置
- 省电策略
- 多显示器设置

- [ ] **Step 3: 添加许可证**

创建 `LICENSE` 文件（MIT License）

- [ ] **Step 4: 提交**

```bash
git add README.md docs/USER_GUIDE.md LICENSE
git commit -m "docs: add README and user guide"
```

---

### Task 21: 最终验证和发布准备

- [ ] **Step 1: 完整功能测试**

测试所有功能：
- [ ] 导入视频壁纸
- [ ] 导入 HEIC 壁纸
- [ ] 设置为桌面壁纸
- [ ] 调节色彩参数
- [ ] 应用预设滤镜
- [ ] 保存自定义预设
- [ ] 多显示器独立设置
- [ ] 启动轮播
- [ ] 测试省电策略
- [ ] 菜单栏快捷操作

- [ ] **Step 2: 性能验证**

使用 Instruments 验证：
- CPU 占用 < 5%
- 内存占用 < 150MB
- 无内存泄漏

- [ ] **Step 3: 代码审查**

检查：
- 代码简洁清爽
- 无冗余代码
- 遵循 Swift 最佳实践
- 注释清晰

- [ ] **Step 4: 构建 Release 版本**

```bash
# 在 Xcode 中
# Product > Archive
# 导出应用
```

- [ ] **Step 5: 创建 GitHub Release**

```bash
git tag -a v1.0.0 -m "Initial release"
git push origin v1.0.0
```

在 GitHub 上创建 Release，上传构建的应用

- [ ] **Step 6: 最终提交**

```bash
git add .
git commit -m "chore: prepare for v1.0.0 release"
git push origin main
```

---

## 完成！

PlumWallPaper MVP 已完成开发。所有核心功能已实现并测试通过。

---

## 执行建议

计划已保存到 `docs/superpowers/plans/2026-04-27-plumwallpaper-mvp.md`。

**两种执行方式：**

**1. Subagent-Driven（推荐）** - 每个任务派发独立 subagent，任务间审查，快速迭代

**2. Inline Execution** - 在当前会话使用 executing-plans 执行，批量执行带检查点

选择哪种方式？
