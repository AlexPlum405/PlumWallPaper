# 播放设置功能增强 · 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. 涉及前端 UI 样式/CSS 布局的工作必须激活 huashu-design skill 来实现。

**Goal:** 完善播放设置菜单的全部功能：播放速率即时生效、循环模式、播放进度控制、单壁纸音量、音频闪避、完整轮播调度器。

**Architecture:** 后端 Swift 层修改 BasicVideoRenderer / WallpaperEngine / WebBridge / Settings / Wallpaper 模型，新增 SlideshowScheduler 和 AudioDuckingMonitor。前端在 plumwallpaper.html 中修改设置页和预览页。

**Tech Stack:** Swift (AVFoundation, MediaRemote, SwiftData), React (inline JSX), Xcode

---

## File Structure

### 修改

| 文件 | 职责 |
|------|------|
| `Sources/Core/WallpaperEngine/WallpaperEngine.swift` | 新增细粒度更新方法、枚举渲染器方法 |
| `Sources/Storage/Models/Settings.swift` | 新增 loopMode / randomStartPosition / audioScreenId / slideshowSource / slideshowTagId 字段 |
| `Sources/Storage/Models/Wallpaper.swift` | 新增 volumeOverride 字段 |
| `Sources/Bridge/WebBridge.swift` | 新增 bridge 方法、序列化新字段、细粒度设置响应链 |
| `Sources/UI/AppViewModel.swift` | 轮播回调注册、启动时轮播初始化 |
| `Sources/Core/PauseStrategyManager.swift` | 暂停/恢复时通知轮播调度器 |
| `Sources/Resources/Web/plumwallpaper.html` | 播放 Tab UI、音频 Tab UI、预览页进度条 |

### 新增

| 文件 | 职责 |
|------|------|
| `Sources/Core/SlideshowScheduler.swift` | 轮播调度器 |
| `Sources/Core/AudioDuckingMonitor.swift` | 音频闪避监控 |

---

## P0 Tasks

### Task 1: 数据模型变更（Settings + Wallpaper）

**Files:**
- Modify: `Sources/Storage/Models/Settings.swift`
- Modify: `Sources/Storage/Models/Wallpaper.swift`

- [ ] **Step 1: Settings 新增字段**

```swift
// Settings.swift — 在 MARK: - Audio 区块末尾、screenOrder 之前添加

/// 循环模式 ("loop" | "once")
var loopMode: String

/// 随机起始位置
var randomStartPosition: Bool

/// 音频输出屏幕 (nil = 主屏幕)
var audioScreenId: String?

/// 轮播来源 ("all" | "favorites" | "tag")
var slideshowSource: String

/// 轮播指定标签 ID
var slideshowTagId: String?
```

在 `init(...)` 中添加对应参数和赋值：

```swift
init(
    // ... 现有参数 ...
    loopMode: String = "loop",
    randomStartPosition: Bool = false,
    audioScreenId: String? = nil,
    slideshowSource: String = "all",
    slideshowTagId: String? = nil,
    fpsLimit: Int? = 0,
    appRulesJSON: String? = nil
) {
    // ... 现有赋值 ...
    self.loopMode = loopMode
    self.randomStartPosition = randomStartPosition
    self.audioScreenId = audioScreenId
    self.slideshowSource = slideshowSource
    self.slideshowTagId = slideshowTagId
    self.fpsLimit = fpsLimit
    self.appRulesJSON = appRulesJSON
}
```

- [ ] **Step 2: Wallpaper 新增字段**

```swift
// Wallpaper.swift — 在 frameRate 字段之后添加

/// 单壁纸音量覆盖 (nil = 跟随全局, 0-100 = 自定义相对音量)
var volumeOverride: Int?
```

在 `init(...)` 中添加：

```swift
init(
    // ... 现有参数 ...
    frameRate: Int? = nil,
    volumeOverride: Int? = nil
) {
    // ... 现有赋值 ...
    self.frameRate = frameRate
    self.volumeOverride = volumeOverride
}
```

- [ ] **Step 3: 构建验证**

```bash
cd PlumWallPaper && xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add Sources/Storage/Models/Settings.swift Sources/Storage/Models/Wallpaper.swift
git commit -m "feat: 新增播放增强相关数据模型字段"
```

---

### Task 2: BasicVideoRenderer 细粒度控制方法

**Files:**
- Modify: `Sources/Core/WallpaperEngine/WallpaperEngine.swift` (BasicVideoRenderer 部分)

- [ ] **Step 1: 重构 BasicVideoRenderer 内部状态管理**

在 `BasicVideoRenderer` 中：

1. 将 `volume` 属性重命名为 `targetVolume`
2. 新增 `currentFPSLimit` 属性
3. 新增 `loopMode` 属性和 `screenId` 属性
4. 新增 `applyEffectiveRate()` 私有方法
5. 新增 `applyEffectiveVolume()` 私有方法
6. 修改 `resume()` 调用 `applyEffectiveRate()`
7. 新增 `setPlaybackRate(_:)` / `setVolume(_:)` / `setFPSLimit(_:)` 公开方法

```swift
final class BasicVideoRenderer: WallpaperRenderer {
    private let wallpaper: Wallpaper
    private let screen: NSScreen
    private let colorSpace: CGColorSpace
    private let performanceMode: Bool
    private let panoramaCrop: CGRect?
    private var targetVolume: Float
    private let opacity: Float
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var hostingWindow: NSWindow?
    private var looper: AVPlayerLooper?
    private var currentItem: AVPlayerItem?
    private var nominalFrameRate: Float = 30
    private var rate: Float
    private var currentFPSLimit: Int = 0
    private let loopMode: String
    private let screenId: String
    private var endObserver: NSObjectProtocol?

    init(wallpaper: Wallpaper, screen: NSScreen, colorSpace: CGColorSpace, performanceMode: Bool, panoramaCrop: CGRect? = nil, volume: Float = 0.5, muted: Bool = false, playbackRate: Float = 1.0, opacity: Float = 1.0, loopMode: String = "loop", screenId: String = "", fpsLimit: Int = 0) {
        self.wallpaper = wallpaper
        self.screen = screen
        self.colorSpace = colorSpace
        self.performanceMode = performanceMode
        self.panoramaCrop = panoramaCrop
        self.targetVolume = volume
        self.rate = playbackRate
        self.opacity = opacity
        self.loopMode = loopMode
        self.screenId = screenId
        self.currentFPSLimit = fpsLimit
    }

    func getActualFPS() -> Float {
        guard let player = player else { return 0 }
        if player.timeControlStatus == .paused { return 0 }
        return player.rate * nominalFrameRate
    }

    // 新增：细粒度控制方法
    func setPlaybackRate(_ newRate: Float) {
        rate = newRate
        applyEffectiveRate()
    }

    func setVolume(_ volume: Float) {
        targetVolume = volume
        applyEffectiveVolume()
    }

    override func setFPSLimit(_ limit: Int) {
        currentFPSLimit = limit
        applyEffectiveRate()
    }

    func setMuted(_ muted: Bool) {
        player?.isMuted = muted
        applyEffectiveVolume()
    }

    var isMuted: Bool {
        player?.isMuted ?? false
    }

    private func applyEffectiveRate() {
        guard let player else { return }
        if currentFPSLimit > 0 && nominalFrameRate > 0 {
            let maxRate = Float(currentFPSLimit) / nominalFrameRate
            player.rate = min(rate, maxRate)
        } else {
            player.rate = rate
        }
    }

    private func applyEffectiveVolume() {
        guard let player else { return }
        player.volume = player.isMuted ? 0 : targetVolume
    }

    func resume() {
        applyEffectiveRate()
    }
```

- [ ] **Step 2: 修改 start() 支持循环模式和随机起始位置**

```swift
    func start() {
        let asset = AVAsset(url: URL(fileURLWithPath: wallpaper.filePath))
        let item = AVPlayerItem(asset: asset)

        if let videoTrack = asset.tracks(withMediaType: .video).first {
            self.nominalFrameRate = videoTrack.nominalFrameRate
        }

        if !performanceMode {
            item.preferredMaximumResolution = CGSize(width: 1920, height: 1080)
        }

        if let preset = wallpaper.filterPreset {
            item.videoComposition = FilterEngine.shared.videoComposition(for: asset, preset: preset)
        }
        self.currentItem = item
        let queuePlayer = AVQueuePlayer(playerItem: item)

        if loopMode == "loop" {
            self.looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        } else {
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.handlePlaybackFinished()
            }
        }

        self.player = queuePlayer

        // ... 窗口创建代码保持不变 ...

        queuePlayer.isMuted = /* muted 参数 */
        applyEffectiveVolume()
        applyEffectiveRate()

        // 随机起始位置（仅 loop 模式）
        if loopMode == "loop" && WallpaperEngine.shared.randomStartPosition {
            let duration = asset.duration.seconds
            if duration > 0 && !duration.isNaN {
                let randomTime = CMTime(seconds: Double.random(in: 0..<duration), preferredTimescale: 600)
                queuePlayer.seek(to: randomTime, toleranceBefore: .zero, toleranceAfter: .zero)
            }
        }
    }

    private func handlePlaybackFinished() {
        player?.pause()
        NotificationCenter.default.post(
            name: Notification.Name("WallpaperDidFinishPlaying"),
            object: nil,
            userInfo: ["wallpaperId": wallpaper.id, "screenId": screenId]
        )
    }
```

- [ ] **Step 3: 修改 stop() 清理 endObserver**

```swift
    func stop() {
        if let observer = endObserver {
            NotificationCenter.default.removeObserver(observer)
            endObserver = nil
        }
        let p = player
        let l = looper
        let pl = playerLayer
        let w = hostingWindow

        player = nil
        looper = nil
        playerLayer = nil
        hostingWindow = nil
        currentItem = nil

        p?.pause()
        p?.replaceCurrentItem(with: nil)
        _ = l
        pl?.removeFromSuperlayer()
        pl?.player = nil
        w?.contentView = nil
        w?.orderOut(nil)
    }
```

- [ ] **Step 4: 构建验证**

```bash
cd PlumWallPaper && xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build 2>&1 | tail -5
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add Sources/Core/WallpaperEngine/WallpaperEngine.swift
git commit -m "feat: BasicVideoRenderer 细粒度控制方法 + 循环模式支持"
```

---

### Task 3: WallpaperEngine 细粒度更新方法

**Files:**
- Modify: `Sources/Core/WallpaperEngine/WallpaperEngine.swift` (WallpaperEngine 部分)

- [ ] **Step 1: 新增细粒度方法和枚举方法**

在 `WallpaperEngine` 类中添加：

```swift
    // MARK: - 随机起始位置（供 BasicVideoRenderer 读取）
    var randomStartPosition: Bool = false

    /// 细粒度：更新播放速率（即时生效）
    func updatePlaybackRate(_ rate: Double) {
        self.playbackRate = Float(rate)
        for renderer in renderers.values {
            if let video = renderer as? BasicVideoRenderer {
                video.setPlaybackRate(Float(rate))
            }
        }
    }

    /// 细粒度：更新全局音量（即时生效，联动所有渲染器）
    func updateGlobalVolume(_ volume: Int) {
        self.globalVolume = Float(volume) / 100.0
        for (screenId, (wallpaper, _)) in activeWallpapers {
            guard let renderer = renderers[screenId] as? BasicVideoRenderer else { continue }
            let baseVolume = Float(wallpaper.volumeOverride ?? 100) / 100.0
            let effective = baseVolume * self.globalVolume
            renderer.setVolume(effective)
        }
    }

    /// 细粒度：更新静音策略（即时生效）
    func updateMutingPolicy(defaultMuted: Bool, previewOnly: Bool) {
        self.defaultMuted = defaultMuted
        self.previewOnlyAudio = previewOnly
        let audioScreenId = /* 从 settings 获取，或作为参数传入 */
        updateAudioScreenMuting(audioScreenId: audioScreenId)
    }

    /// 细粒度：更新音频输出屏幕静音状态（不重建渲染器）
    func updateAudioScreenMuting(audioScreenId: String?) {
        for (screenId, renderer) in renderers {
            guard let video = renderer as? BasicVideoRenderer else { continue }
            let screenInfo = activeWallpapers[screenId]?.1
            let isAudioScreen = (audioScreenId == nil && (screenInfo?.isMain ?? false)) ||
                                (audioScreenId == screenId)
            if isAudioScreen {
                video.setMuted(defaultMuted || previewOnlyAudio)
            } else {
                video.setMuted(true)
            }
        }
    }

    /// 更新单壁纸音量
    func updateWallpaperVolume(wallpaperId: UUID) {
        for (screenId, (wallpaper, _)) in activeWallpapers {
            guard wallpaper.id == wallpaperId else { continue }
            guard let renderer = renderers[screenId] as? BasicVideoRenderer else { continue }
            let baseVolume = Float(wallpaper.volumeOverride ?? 100) / 100.0
            let effective = baseVolume * globalVolume
            renderer.setVolume(effective)
        }
    }

    /// 枚举所有渲染器
    func enumerateRenderers(_ block: (String, WallpaperRenderer) -> Void) {
        for (key, renderer) in renderers {
            block(key, renderer)
        }
    }

    /// 枚举音频屏幕的视频渲染器
    func enumerateAudioRenderer(_ block: (String, BasicVideoRenderer) -> Void) {
        for (key, renderer) in renderers {
            if let video = renderer as? BasicVideoRenderer {
                block(key, video)
            }
        }
    }

    /// 当前所有屏幕正在显示的壁纸 ID
    var activeWallpaperIds: Set<UUID> {
        Set(activeWallpapers.values.map { $0.0.id })
    }
```

- [ ] **Step 2: 修改 setWallpaper 传入 loopMode / screenId / fpsLimit**

在 `setWallpaper(_:for:)` 中修改 `BasicVideoRenderer` 初始化：

```swift
case .video:
    let audioScreenId = /* 从 settings 获取 */
    let isAudioScreen = (audioScreenId == nil && screenInfo.isMain) ||
                        (audioScreenId == key)
    let shouldMute = !isAudioScreen || defaultMuted || previewOnlyAudio
    let baseVolume = Float(wallpaper.volumeOverride ?? 100) / 100.0
    let effectiveVolume = baseVolume * globalVolume

    renderer = BasicVideoRenderer(
        wallpaper: wallpaper,
        screen: screen,
        colorSpace: activeColorSpace,
        performanceMode: performanceMode,
        volume: effectiveVolume,
        muted: shouldMute,
        playbackRate: playbackRate,
        opacity: wallpaperOpacity,
        loopMode: loopMode,
        screenId: key,
        fpsLimit: fpsLimit
    )
```

同样修改 `setWallpaperPanorama` 中的初始化。

- [ ] **Step 3: 新增 loopMode / audioScreenId 属性**

```swift
var loopMode: String = "loop"
var audioScreenId: String? = nil
```

- [ ] **Step 4: 修改 setWallpaper 支持重新播放同一壁纸**

在 `setWallpaper(_:for:)` 开头添加：

```swift
if let (existingWallpaper, _) = activeWallpapers[key],
   existingWallpaper.id == wallpaper.id,
   let existingRenderer = renderers[key] as? BasicVideoRenderer {
    existingRenderer.seekToBeginning()
    return
}
```

在 `BasicVideoRenderer` 中添加：

```swift
func seekToBeginning() {
    player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
    applyEffectiveRate()
}
```

- [ ] **Step 5: 构建验证**

```bash
cd PlumWallPaper && xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build 2>&1 | tail -5
```

- [ ] **Step 6: Commit**

```bash
git add Sources/Core/WallpaperEngine/WallpaperEngine.swift
git commit -m "feat: WallpaperEngine 细粒度更新方法 + 音频屏幕 + 循环模式"
```

---

### Task 4: WebBridge 序列化 / 反序列化 + 细粒度设置响应链

**Files:**
- Modify: `Sources/Bridge/WebBridge.swift`

- [ ] **Step 1: serializeSettings 新增字段**

在 `serializeSettings(_:)` 返回字典中添加：

```swift
"loopMode": s.loopMode,
"randomStartPosition": s.randomStartPosition,
"audioScreenId": s.audioScreenId as Any,
"slideshowSource": s.slideshowSource,
"slideshowTagId": s.slideshowTagId as Any,
```

- [ ] **Step 2: serializeWallpaper 新增字段**

在 `serializeWallpaper(_:)` 中，`hasAudio` 之后添加：

```swift
if let vol = w.volumeOverride { dict["volumeOverride"] = vol }
```

- [ ] **Step 3: applySettingsUpdate 新增字段解析**

在 `applySettingsUpdate(_:from:)` 中添加：

```swift
if let v = d["loopMode"] as? String { s.loopMode = v }
if let v = d["randomStartPosition"] as? Bool { s.randomStartPosition = v }
if let v = d["audioScreenId"] as? String { s.audioScreenId = v }
if d["audioScreenId"] is NSNull { s.audioScreenId = nil }
if let v = d["slideshowSource"] as? String { s.slideshowSource = v }
if let v = d["slideshowTagId"] as? String { s.slideshowTagId = v }
if d["slideshowTagId"] is NSNull { s.slideshowTagId = nil }
```

- [ ] **Step 4: 重构 updateSettings 的设置响应链**

替换现有的音频设置变更块（312-319行）为细粒度响应：

```swift
// 播放速率变化
if settings.playbackRate != oldRate {
    WallpaperEngine.shared.updatePlaybackRate(settings.playbackRate ?? 1.0)
}

// 全局音量变化
if settings.globalVolume != oldVolume {
    WallpaperEngine.shared.updateGlobalVolume(settings.globalVolume ?? 50)
}

// 静音策略变化
if settings.defaultMuted != oldMuted || settings.previewOnlyAudio != oldPreviewOnly {
    WallpaperEngine.shared.updateMutingPolicy(
        defaultMuted: settings.defaultMuted ?? false,
        previewOnly: settings.previewOnlyAudio ?? false
    )
}

// 循环模式变化
let oldLoopMode = /* 保存旧值 */
if settings.loopMode != oldLoopMode {
    WallpaperEngine.shared.loopMode = settings.loopMode
    WallpaperEngine.shared.reloadAllRenderers()
}

// 随机起始位置
WallpaperEngine.shared.randomStartPosition = settings.randomStartPosition

// 音频输出屏幕变化
let oldAudioScreenId = /* 保存旧值 */
if settings.audioScreenId != oldAudioScreenId {
    WallpaperEngine.shared.audioScreenId = settings.audioScreenId
    WallpaperEngine.shared.updateAudioScreenMuting(audioScreenId: settings.audioScreenId)
}

// 音频闪避变化
let oldDucking = /* 保存旧值 */
if settings.audioDuckingEnabled != oldDucking {
    AudioDuckingMonitor.shared.startMonitoring(
        enabled: settings.audioDuckingEnabled && !(settings.previewOnlyAudio ?? false)
    )
}

// 轮播参数变化
let oldSlideshowEnabled = /* 保存旧值 */
if settings.slideshowEnabled != oldSlideshowEnabled {
    if settings.slideshowEnabled {
        SlideshowScheduler.shared.start(context: modelContext, settings: settings)
    } else {
        SlideshowScheduler.shared.stop()
    }
}
let oldInterval = /* 保存旧值 */
if settings.slideshowInterval != oldInterval {
    SlideshowScheduler.shared.updateInterval(settings.slideshowInterval)
}
let oldSource = /* 保存旧值 */
let oldOrder = /* 保存旧值 */
let oldTagId = /* 保存旧值 */
if settings.slideshowSource != oldSource ||
   settings.slideshowOrder != oldOrder ||
   settings.slideshowTagId != oldTagId {
    SlideshowScheduler.shared.rebuildPlaylist()
}
```

- [ ] **Step 5: 新增 bridge 方法 — setWallpaperVolume**

在 `case` 分支中添加：

```swift
case "setWallpaperVolume":
    guard let wallpaperIdStr = params["wallpaperId"] as? String,
          let wallpaperId = UUID(uuidString: wallpaperIdStr),
          let volume = params["volume"] as? Int else {
        return fail("Missing wallpaperId or volume")
    }
    let descriptor = FetchDescriptor<Wallpaper>(predicate: #Predicate { $0.id == wallpaperId })
    guard let wallpaper = try modelContext.fetch(descriptor).first else {
        return fail("Wallpaper not found")
    }
    wallpaper.volumeOverride = volume
    try modelContext.save()
    WallpaperEngine.shared.updateWallpaperVolume(wallpaperId: wallpaperId)
    return success([:] as [String: Any])
```

- [ ] **Step 6: 新增 bridge 方法 — getAvailableScreens**

```swift
case "getAvailableScreens":
    let screens = DisplayManager.shared.availableScreens.map { screen -> [String: Any] in
        ["id": screen.id, "name": screen.name, "isMain": screen.isMain]
    }
    return success(["screens": screens])
```

- [ ] **Step 7: 在壁纸操作后触发轮播列表重建**

在以下 case 分支的成功返回前添加 `SlideshowScheduler.shared.rebuildPlaylist()`：
- `importFiles`（导入成功后）
- `deleteWallpaper`（删除后）
- `toggleFavorite`（收藏切换后）
- `createTag` / `deleteTag`（标签变化后）

- [ ] **Step 8: 构建验证**

```bash
cd PlumWallPaper && xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build 2>&1 | tail -5
```

- [ ] **Step 9: Commit**

```bash
git add Sources/Bridge/WebBridge.swift
git commit -m "feat: WebBridge 序列化新字段 + 细粒度设置响应链 + setWallpaperVolume"
```

---

### Task 5: SlideshowScheduler 轮播调度器

**Files:**
- Create: `Sources/Core/SlideshowScheduler.swift`
- Modify: `PlumWallPaper.xcodeproj/project.pbxproj`（添加新文件引用）

- [ ] **Step 1: 创建 SlideshowScheduler.swift**

```swift
import Foundation
import SwiftData

@MainActor
final class SlideshowScheduler {
    static let shared = SlideshowScheduler()

    private var timer: Timer?
    private var playlistIds: [UUID] = []
    private var currentIndex: Int = 0
    private var isPaused = false
    private var isAutoSwitching = false
    private weak var modelContext: ModelContext?
    private var currentInterval: TimeInterval = 1800
    private var currentOrder: SlideshowOrder = .sequential

    var onSwitchWallpaper: ((Wallpaper) -> Void)?

    private init() {}

    func start(context: ModelContext, settings: Settings) {
        self.modelContext = context
        self.currentInterval = settings.slideshowInterval
        self.currentOrder = settings.slideshowOrder
        buildPlaylist(context: context, settings: settings)

        guard !playlistIds.isEmpty else { return }

        let currentIds = WallpaperEngine.shared.activeWallpaperIds
        if let firstActive = currentIds.first,
           let idx = playlistIds.firstIndex(of: firstActive) {
            currentIndex = idx
        } else {
            currentIndex = 0
        }

        startTimer(interval: currentInterval)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        playlistIds = []
        currentIndex = 0
        isPaused = false
    }

    func next() {
        guard !playlistIds.isEmpty else { return }
        guard let context = modelContext else { stop(); return }

        currentIndex = (currentIndex + 1) % playlistIds.count

        let currentlyShowing = WallpaperEngine.shared.activeWallpaperIds
        if playlistIds.count > 1 && currentlyShowing.contains(playlistIds[currentIndex]) {
            currentIndex = (currentIndex + 1) % playlistIds.count
        }

        let id = playlistIds[currentIndex]
        let descriptor = FetchDescriptor<Wallpaper>(predicate: #Predicate { $0.id == id })
        guard let wallpaper = try? context.fetch(descriptor).first else { return }

        isAutoSwitching = true
        onSwitchWallpaper?(wallpaper)
        isAutoSwitching = false
        resetTimer()
    }

    func prev() {
        guard !playlistIds.isEmpty else { return }
        guard let context = modelContext else { stop(); return }

        currentIndex = (currentIndex - 1 + playlistIds.count) % playlistIds.count
        let id = playlistIds[currentIndex]
        let descriptor = FetchDescriptor<Wallpaper>(predicate: #Predicate { $0.id == id })
        guard let wallpaper = try? context.fetch(descriptor).first else { return }

        isAutoSwitching = true
        onSwitchWallpaper?(wallpaper)
        isAutoSwitching = false
        resetTimer()
    }

    func pause() {
        isPaused = true
        timer?.fireDate = Date.distantFuture
    }

    func resume() {
        isPaused = false
        resetTimer()
    }

    func rebuildPlaylist() {
        guard let context = modelContext else { return }
        guard let settings = try? PreferencesStore(modelContext: context).fetchSettings() else { return }
        let oldId = playlistIds.indices.contains(currentIndex) ? playlistIds[currentIndex] : nil
        buildPlaylist(context: context, settings: settings)
        if let oldId, let idx = playlistIds.firstIndex(of: oldId) {
            currentIndex = idx
        } else {
            currentIndex = 0
        }
    }

    func updateInterval(_ interval: TimeInterval) {
        currentInterval = interval
        resetTimer()
    }

    func onWallpaperChanged(_ wallpaperId: UUID) {
        guard !isAutoSwitching else { return }
        if let index = playlistIds.firstIndex(of: wallpaperId) {
            currentIndex = index
        }
        resetTimer()
    }

    func getStatus() -> (current: Int, total: Int, nextIn: Int) {
        let nextIn: Int
        if let timer = timer, !isPaused {
            nextIn = max(0, Int(timer.fireDate.timeIntervalSinceNow))
        } else {
            nextIn = 0
        }
        return (current: currentIndex + 1, total: playlistIds.count, nextIn: nextIn)
    }

    // MARK: - Private

    private func buildPlaylist(context: ModelContext, settings: Settings) {
        let wallpapers: [Wallpaper]
        switch settings.slideshowSource {
        case "favorites":
            let descriptor = FetchDescriptor<Wallpaper>(predicate: #Predicate { $0.isFavorite == true })
            wallpapers = (try? context.fetch(descriptor)) ?? []
        case "tag":
            if let tagId = settings.slideshowTagId,
               let tagUUID = UUID(uuidString: tagId) {
                let tagDescriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.id == tagUUID })
                if let tag = try? context.fetch(tagDescriptor).first {
                    wallpapers = tag.wallpapers
                } else {
                    wallpapers = []
                }
            } else {
                wallpapers = []
            }
        default:
            let descriptor = FetchDescriptor<Wallpaper>()
            wallpapers = (try? context.fetch(descriptor)) ?? []
        }

        playlistIds = applySorting(wallpapers, order: settings.slideshowOrder).map(\.id)
    }

    private func applySorting(_ wallpapers: [Wallpaper], order: SlideshowOrder) -> [Wallpaper] {
        switch order {
        case .random:
            return wallpapers.shuffled()
        case .favoritesFirst:
            let favs = wallpapers.filter { $0.isFavorite }.sorted { $0.importDate < $1.importDate }
            let rest = wallpapers.filter { !$0.isFavorite }.sorted { $0.importDate < $1.importDate }
            return favs + rest
        case .sequential:
            return wallpapers.sorted { $0.importDate < $1.importDate }
        }
    }

    private func startTimer(interval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.next() }
        }
    }

    private func resetTimer() {
        guard let timer, !isPaused else { return }
        timer.fireDate = Date().addingTimeInterval(currentInterval)
    }
}
```

- [ ] **Step 2: 将文件添加到 Xcode 项目**

手动将 `SlideshowScheduler.swift` 添加到 `project.pbxproj`（PBXBuildFile + PBXFileReference + Core group + Sources build phase）。

- [ ] **Step 3: 构建验证**

```bash
cd PlumWallPaper && xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build 2>&1 | tail -5
```

- [ ] **Step 4: Commit**

```bash
git add Sources/Core/SlideshowScheduler.swift PlumWallPaper.xcodeproj/project.pbxproj
git commit -m "feat: 新增 SlideshowScheduler 轮播调度器"
```

---

### Task 6: AppViewModel 集成轮播 + PauseStrategy 联动

**Files:**
- Modify: `Sources/UI/AppViewModel.swift`
- Modify: `Sources/Core/PauseStrategyManager.swift`
- Modify: `Sources/Bridge/WebBridge.swift`（新增 slideshowNext/Prev/Status bridge 方法）

- [ ] **Step 1: AppViewModel 注册轮播回调**

在 `AppViewModel` 中添加：

```swift
func setupSlideshow() {
    SlideshowScheduler.shared.onSwitchWallpaper = { [weak self] wallpaper in
        self?.smartSetWallpaper(wallpaper)
    }
}
```

- [ ] **Step 2: AppViewModel.setWallpaper 通知轮播**

在 `setWallpaper(_:for:)` 末尾添加：

```swift
SlideshowScheduler.shared.onWallpaperChanged(wallpaper.id)
```

同样在 `setWallpaperToAll(_:)` 末尾添加。

- [ ] **Step 3: restoreLastSession 中启动轮播**

在 `restoreLastSession(context:)` 末尾添加：

```swift
if let settings = try? PreferencesStore(modelContext: context).fetchSettings(),
   settings.slideshowEnabled {
    setupSlideshow()
    SlideshowScheduler.shared.start(context: context, settings: settings)
}
```

- [ ] **Step 4: PauseStrategyManager 联动轮播**

在 `PauseStrategyManager` 的暂停触发处添加：

```swift
SlideshowScheduler.shared.pause()
```

在恢复处添加：

```swift
SlideshowScheduler.shared.resume()
```

- [ ] **Step 5: WebBridge 新增轮播控制方法**

```swift
case "slideshowNext":
    SlideshowScheduler.shared.next()
    return success([:] as [String: Any])

case "slideshowPrev":
    SlideshowScheduler.shared.prev()
    return success([:] as [String: Any])

case "getSlideshowStatus":
    let status = SlideshowScheduler.shared.getStatus()
    return success([
        "current": status.current,
        "total": status.total,
        "nextIn": status.nextIn
    ])
```

- [ ] **Step 6: 构建验证**

```bash
cd PlumWallPaper && xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build 2>&1 | tail -5
```

- [ ] **Step 7: Commit**

```bash
git add Sources/UI/AppViewModel.swift Sources/Core/PauseStrategyManager.swift Sources/Bridge/WebBridge.swift
git commit -m "feat: AppViewModel 集成轮播 + PauseStrategy 联动"
```

---

### Task 7: 前端播放 Tab UI + 音频 Tab UI（使用 huashu-design）

**Files:**
- Modify: `Sources/Resources/Web/plumwallpaper.html`

> **注意：** 本 Task 涉及前端 UI 样式/CSS 布局，必须激活 huashu-design skill 来实现。

- [ ] **Step 1: 播放 Tab — 循环模式选择**

在播放速度下方、自动轮播上方添加循环模式按钮组：

```jsx
<SettingRow title="循环模式" desc="视频播放完成后的行为">
  <div style={{ display: 'flex', gap: 8 }}>
    {[{v:'loop',l:'循环播放'},{v:'once',l:'播完停止'}].map(({v,l}) =>
      <button key={v} className="btn"
        onClick={() => updateSetting('loopMode', v)}
        style={{
          padding: '6px 12px', fontSize: 12,
          background: (s.loopMode || 'loop') === v ? 'rgba(255,255,255,0.14)' : undefined,
          color: (s.loopMode || 'loop') === v ? '#fff' : undefined,
          fontWeight: (s.loopMode || 'loop') === v ? 700 : undefined,
          borderColor: (s.loopMode || 'loop') === v ? 'rgba(255,255,255,0.24)' : undefined
        }}>{l}</button>
    )}
  </div>
</SettingRow>
```

- [ ] **Step 2: 播放 Tab — 随机起始位置开关**

在循环模式下方添加：

```jsx
<SettingRow title="随机起始位置" desc="循环播放时从视频随机位置开始">
  <Switch active={!!s.randomStartPosition} onToggle={() => updateSetting('randomStartPosition', !s.randomStartPosition)} />
</SettingRow>
```

- [ ] **Step 3: 播放 Tab — 解除轮播区块禁用**

移除轮播区块的 `opacity: 0.35` 和 `pointerEvents: 'none'`，移除"后续版本"标签。

绑定所有控件：
- 启用开关 → `updateSetting('slideshowEnabled', !s.slideshowEnabled)`
- 间隔按钮 → `updateSetting('slideshowInterval', seconds)`
- 顺序按钮 → `updateSetting('slideshowOrder', value)`

新增播放列表来源选择：

```jsx
<SettingRow title="播放列表来源" desc="选择参与轮播的壁纸范围">
  <div style={{ display: 'flex', gap: 8 }}>
    {[{v:'all',l:'全部'},{v:'favorites',l:'收藏'},{v:'tag',l:'指定标签'}].map(({v,l}) =>
      <button key={v} className="btn"
        onClick={() => updateSetting('slideshowSource', v)}
        style={{
          padding: '6px 12px', fontSize: 12,
          background: (s.slideshowSource || 'all') === v ? 'rgba(255,255,255,0.14)' : undefined,
          color: (s.slideshowSource || 'all') === v ? '#fff' : undefined,
          fontWeight: (s.slideshowSource || 'all') === v ? 700 : undefined,
          borderColor: (s.slideshowSource || 'all') === v ? 'rgba(255,255,255,0.24)' : undefined
        }}>{l}</button>
    )}
  </div>
</SettingRow>
```

当 source === 'tag' 时显示标签下拉。

- [ ] **Step 4: 播放 Tab — 轮播状态行 + prev/next 按钮**

在轮播区块顶部添加状态行（仅 slideshowEnabled 时显示）。

- [ ] **Step 5: 音频 Tab — 音频输出屏幕下拉**

在全局音量滑块下方添加：

```jsx
<SettingRow title="音频输出屏幕" desc="多屏幕时仅允许选定屏幕的壁纸播放音频">
  <select value={s.audioScreenId || ''} onChange={e => updateSetting('audioScreenId', e.target.value || null)}
    style={{ /* 样式由 huashu-design 决定 */ }}>
    <option value="">主屏幕</option>
    {availableScreens.map(sc => <option key={sc.id} value={sc.id}>{sc.name}</option>)}
  </select>
</SettingRow>
```

- [ ] **Step 6: 音频 Tab — 解除音频闪避禁用**

移除音频闪避行的 `opacity: 0.35` 和 `pointerEvents: 'none'`，移除"后续版本"标签。

绑定开关：`updateSetting('audioDuckingEnabled', !s.audioDuckingEnabled)`

- [ ] **Step 7: 构建验证（浏览器测试）**

启动应用，打开设置页，验证：
- 播放 Tab 所有控件可交互
- 音频 Tab 新增控件可见
- 轮播区块不再灰色禁用

- [ ] **Step 8: Commit**

```bash
git add Sources/Resources/Web/plumwallpaper.html
git commit -m "feat: 播放 Tab + 音频 Tab 前端 UI 完善"
```

---

## P1 Tasks

### Task 8: AudioDuckingMonitor 音频闪避

**Files:**
- Create: `Sources/Core/AudioDuckingMonitor.swift`
- Modify: `PlumWallPaper.xcodeproj/project.pbxproj`
- Modify: `Sources/Bridge/WebBridge.swift`（启动时初始化）

- [ ] **Step 1: 创建 AudioDuckingMonitor.swift**

```swift
import Foundation

@MainActor
final class AudioDuckingMonitor {
    static let shared = AudioDuckingMonitor()

    private var timer: Timer?
    private var isOtherAppPlaying = false
    private var preDuckingMuteStates: [String: Bool] = [:]

    private typealias MRGetNowPlayingInfoFn = @convention(c) (DispatchQueue, @escaping ([String: Any]?) -> Void) -> Void
    private let getNowPlayingInfo: MRGetNowPlayingInfoFn?

    private init() {
        let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY)
        if let handle, let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") {
            getNowPlayingInfo = unsafeBitCast(sym, to: MRGetNowPlayingInfoFn.self)
        } else {
            getNowPlayingInfo = nil
            NSLog("[AudioDucking] MediaRemote.framework not available, ducking disabled")
        }
    }

    func startMonitoring(enabled: Bool) {
        timer?.invalidate()
        timer = nil
        guard enabled, getNowPlayingInfo != nil else {
            if isOtherAppPlaying { restoreAudio() }
            isOtherAppPlaying = false
            return
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkNowPlaying() }
        }
    }

    func stopMonitoring() {
        startMonitoring(enabled: false)
    }

    private func checkNowPlaying() {
        getNowPlayingInfo?(DispatchQueue.main) { [weak self] info in
            guard let self else { return }
            let rate = info?["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0
            let isPlaying = rate > 0

            if isPlaying && !self.isOtherAppPlaying {
                self.isOtherAppPlaying = true
                self.muteAudio()
            } else if !isPlaying && self.isOtherAppPlaying {
                self.isOtherAppPlaying = false
                self.restoreAudio()
            }
        }
    }

    private func muteAudio() {
        preDuckingMuteStates.removeAll()
        WallpaperEngine.shared.enumerateAudioRenderer { id, renderer in
            preDuckingMuteStates[id] = renderer.isMuted
            renderer.setMuted(true)
        }
    }

    private func restoreAudio() {
        WallpaperEngine.shared.enumerateAudioRenderer { id, renderer in
            if let wasMuted = preDuckingMuteStates[id] {
                renderer.setMuted(wasMuted)
            }
        }
        preDuckingMuteStates.removeAll()
    }
}
```

- [ ] **Step 2: 添加到 Xcode 项目**

手动将 `AudioDuckingMonitor.swift` 添加到 `project.pbxproj`。

- [ ] **Step 3: WebBridge 启动时初始化闪避**

在 WebBridge 初始化块中（`if let settings = try? self.preferencesStore.fetchSettings()` 内）添加：

```swift
AudioDuckingMonitor.shared.startMonitoring(
    enabled: settings.audioDuckingEnabled && !(settings.previewOnlyAudio ?? false)
)
```

- [ ] **Step 4: 构建验证**

```bash
cd PlumWallPaper && xcodebuild -project PlumWallPaper.xcodeproj -scheme PlumWallPaper -configuration Debug build 2>&1 | tail -5
```

- [ ] **Step 5: Commit**

```bash
git add Sources/Core/AudioDuckingMonitor.swift PlumWallPaper.xcodeproj/project.pbxproj Sources/Bridge/WebBridge.swift
git commit -m "feat: 新增 AudioDuckingMonitor 音频闪避"
```

---

### Task 9: 预览页进度条（使用 huashu-design）

**Files:**
- Modify: `Sources/Resources/Web/plumwallpaper.html`

> **注意：** 本 Task 涉及前端 UI 样式/CSS 布局，必须激活 huashu-design skill 来实现。

- [ ] **Step 1: PreviewPage 新增进度条状态**

在 `PreviewPage` 组件中添加：

```jsx
const [progress, setProgress] = useState(0);
const [duration, setDuration] = useState(0);
const [isDragging, setIsDragging] = useState(false);

useEffect(() => {
  const video = videoRef.current;
  if (!video) return;
  const onTime = () => { if (!isDragging) setProgress(video.currentTime); };
  const onMeta = () => setDuration(video.duration);
  video.addEventListener('timeupdate', onTime);
  video.addEventListener('loadedmetadata', onMeta);
  return () => {
    video.removeEventListener('timeupdate', onTime);
    video.removeEventListener('loadedmetadata', onMeta);
  };
}, [isDragging]);
```

- [ ] **Step 2: 进度条 UI**

在预览页底部渐变区域内、壁纸信息下方添加进度条。

具体样式由 huashu-design 决定，功能要求：
- 显示当前时间 / 总时长（`mm:ss / mm:ss`）
- 可拖拽跳转
- `duration` 为 `NaN` / `Infinity` / `0` 时隐藏
- 仅视频壁纸显示

- [ ] **Step 3: 构建验证**

启动应用，打开预览页，验证进度条显示和拖拽跳转。

- [ ] **Step 4: Commit**

```bash
git add Sources/Resources/Web/plumwallpaper.html
git commit -m "feat: 预览页播放进度条"
```

---

### Task 10: 预览页 + 色彩页音量滑块持久化（使用 huashu-design）

**Files:**
- Modify: `Sources/Resources/Web/plumwallpaper.html`

> **注意：** 本 Task 涉及前端 UI 样式/CSS 布局，必须激活 huashu-design skill 来实现。

- [ ] **Step 1: PreviewPage 音量滑块改为持久化**

修改 `PreviewPage` 组件：

```jsx
const [volume, setVolume] = useState(() => {
  const override = wallpaper.volumeOverride;
  return override != null ? override / 100 : 1.0;
});

// 前端 <video> 实际音量 = baseVolume × globalVolume
useEffect(() => {
  if (videoRef.current) {
    const globalVol = (settings?.globalVolume ?? 50) / 100;
    videoRef.current.volume = volume * globalVol;
    videoRef.current.muted = isMuted;
  }
}, [volume, isMuted]);

// 滑块 onMouseUp 时持久化
const handleVolumeCommit = () => {
  bridge.call('setWallpaperVolume', {
    wallpaperId: wallpaper.id,
    volume: Math.round(volume * 100)
  });
};
```

- [ ] **Step 2: 色彩页音量滑块同样改为持久化**

同样的逻辑应用到色彩调节页的音量滑块。

- [ ] **Step 3: 构建验证**

启动应用，在预览页调节音量，关闭再打开预览页，验证音量已持久化。

- [ ] **Step 4: Commit**

```bash
git add Sources/Resources/Web/plumwallpaper.html
git commit -m "feat: 预览页 + 色彩页音量滑块持久化"
```

---

## P2 Tasks

### Task 11: 壁纸卡片音量 badge（使用 huashu-design）

**Files:**
- Modify: `Sources/Resources/Web/plumwallpaper.html`

> **注意：** 本 Task 涉及前端 UI 样式/CSS 布局，必须激活 huashu-design skill 来实现。

- [ ] **Step 1: 壁纸卡片添加音量 badge**

在壁纸卡片组件中，当 `wallpaper.volumeOverride != null` 时显示音量 badge。

具体样式由 huashu-design 决定。

- [ ] **Step 2: 构建验证**

- [ ] **Step 3: Commit**

```bash
git add Sources/Resources/Web/plumwallpaper.html
git commit -m "feat: 壁纸卡片音量 badge"
```
