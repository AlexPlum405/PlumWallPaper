# 播放设置功能增强 · 设计文档 v5

> **For agentic workers:** Use superpowers:writing-plans to create implementation plan.

**Goal:** 完善播放设置菜单的全部功能，包括播放速率即时生效、循环模式、播放进度控制、单壁纸音量、音频闪避、完整轮播调度器。

**Architecture:** 分为 3 个子系统——播放控制增强、音频系统增强、轮播调度器。前端在 `plumwallpaper.html` 中修改，后端涉及 `WallpaperEngine`、`BasicVideoRenderer`、`WebBridge`、`Settings` / `Wallpaper` 模型，并新增 `SlideshowScheduler` 与 `AudioDuckingMonitor`。

**Tech Stack:** Swift (AVFoundation, MediaRemote, SwiftData), React (inline JSX)

---

## 设计原则

1. **设置变更即时生效，但只用必要粒度刷新。** 能局部更新就不重建渲染器；只有循环模式这类结构性变化才重建。
2. **单壁纸音量是相对值，全局音量是总阀门。** 两者采用乘法关系。
3. **多屏音频始终只有一个输出屏幕。** 默认主屏，可手动指定。
4. **轮播是同步切换同一张壁纸，不做每屏独立轮播。**
5. **预览页播放控制直接操作前端 `<video>`，不绕后端 bridge。**
6. **轮播调度器不直接依赖 AppViewModel。** 通过回调解耦。

---

## 子系统 1：播放控制增强

### 1.1 播放速率即时生效

**问题：** 修改播放速率后，当前播放的壁纸不会立即改变速度，必须重新应用壁纸才生效。

**方案：**
- `BasicVideoRenderer` 新增 `setPlaybackRate(_:)`
- `BasicVideoRenderer` 内部统一用 `applyEffectiveRate()` 处理播放速率与 FPS 上限的交互
- `resume()` 不再直接写 `player.rate`，而是调用 `applyEffectiveRate()`
- `WallpaperEngine` 把“更新全局音量 / 静音策略 / 播放速率”拆成细粒度方法，避免音频设置变化时一律 `reloadAllRenderers()`
- 同时保留 `updateAudioConfig()` 作为“批量写入引擎内部状态”的方法，供启动恢复流程使用

**实现细节：**
```swift
final class BasicVideoRenderer: WallpaperRenderer {
    private var rate: Float
    private var currentFPSLimit: Int = 0
    private var targetVolume: Float

    func setPlaybackRate(_ newRate: Float) {
        rate = newRate
        applyEffectiveRate()
    }

    func setFPSLimit(_ limit: Int) {
        currentFPSLimit = limit
        applyEffectiveRate()
    }

    func resume() {
        applyEffectiveRate()
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
}
```

**状态更新责任划分：**
- `updateAudioConfig(...)`：只更新 `WallpaperEngine` 内部状态变量（`globalVolume` / `defaultMuted` / `previewOnlyAudio` / `playbackRate`）
- `updatePlaybackRate(_:)`：更新内部状态 + 遍历活跃渲染器调用 `setPlaybackRate`
- `updateGlobalVolume(_:)`：更新内部状态 + 遍历活跃渲染器重算 effectiveVolume
- `updateMutingPolicy(...)`：更新内部状态 + 遍历活跃渲染器调整静音状态

### 1.2 循环模式

**数据模型变更：**
- `Settings.loopMode: String = "loop"`

**枚举值：**
- `loop` — 循环播放
- `once` — 播完停止，停在最后一帧

**适用范围：** 仅视频壁纸生效；静态图片（`image` / `heic`）忽略此设置。

**实现策略：**
- `loop` 模式继续使用 `AVPlayerLooper`，保证循环无缝
- `once` 模式不用 looper，监听 `AVPlayerItem.didPlayToEndTime`
- 因为 `AVPlayerLooper` 不能轻量热切换，所以**循环模式变更时重建活跃渲染器**

**结束通知：**
```swift
NotificationCenter.default.addObserver(
    forName: .AVPlayerItemDidPlayToEndTime,
    object: item,
    queue: .main
) { [weak self] _ in
    self?.handlePlaybackFinished()
}
```

`handlePlaybackFinished()`：
- `player.pause()`
- 发送 `Notification.Name("WallpaperDidFinishPlaying")`
- `userInfo = ["wallpaperId": wallpaper.id, "screenId": screenId]`

**重新播放机制：**
- 用户再次应用同一张已播完的 `once` 壁纸时：不直接无操作，而是 seek 到开头并重新播放
- 入口：`WallpaperEngine.setWallpaper()` 中检测“当前屏幕已是同一张壁纸”

**和轮播的交互：**
- 轮播启用时，`once` 模式播完**不立即切换**，仍等待轮播定时器到点切换
- 理由：防止一组 `once` 壁纸按视频时长快速连续切换，破坏用户对“轮播间隔”的预期
- 该 tradeoff 是有意设计：用户选择轮播时，节奏优先由轮播间隔决定，而不是由视频时长决定

**随机起始位置和循环模式交互：**
- `randomStartPosition` 仅在 `loop` 模式下生效
- `once` 模式始终从头开始，保证用户能看完整段视频

**WebBridge 设置更新链路：**
```swift
if settings.loopMode != oldLoopMode {
    WallpaperEngine.shared.reloadAllRenderers()
}
```

### 1.3 播放进度控制

**架构：** 预览页是前端 `<video>`，进度控制直接操作 DOM，不新增 bridge seek API。

**前端预览页新增：**
- 进度条
- 拖拽跳转
- 当前时间 / 总时长文本
- 使用 `timeupdate` 事件更新状态
- `duration` 为 `NaN` / `Infinity` / `0` 时隐藏进度条

**建议 UI 位置：** 预览页底部渐变信息区内，壁纸信息下方，音量按钮上方。

**随机起始位置：**
- `Settings.randomStartPosition: Bool = false`
- 在 `BasicVideoRenderer.start()` 中、创建完 player 后、开始播放前执行随机 seek

---

## 子系统 2：音频系统增强

### 2.1 单壁纸音量持久化

**数据模型：**
- `Wallpaper.volumeOverride: Int? = nil`

含义：
- `nil` → 跟随全局
- `0...100` → 该壁纸的相对音量

**音量模型：**
```swift
let baseVolume = Float(wallpaper.volumeOverride ?? 100) / 100.0
let globalVolume = Float(settings.globalVolume ?? 50) / 100.0
let effectiveVolume = baseVolume * globalVolume
```

**解释：**
- 全局音量：总阀门
- 单壁纸音量：相对系数
- 最终输出：两者相乘

**BasicVideoRenderer 音量实现：**
```swift
final class BasicVideoRenderer: WallpaperRenderer {
    private var targetVolume: Float

    func setVolume(_ volume: Float) {
        targetVolume = volume
        applyEffectiveVolume()
    }

    func setMuted(_ muted: Bool) {
        player?.isMuted = muted
        applyEffectiveVolume()
    }

    private func applyEffectiveVolume() {
        guard let player else { return }
        player.volume = player.isMuted ? 0 : targetVolume
    }
}
```

**后端新增 bridge 方法：**
- `setWallpaperVolume({ wallpaperId, volume })`

**查找当前活跃渲染器的方式：**
- `renderers` 仍保持 `private`
- `activeWallpapers` 仍保持 `private`
- 通过 `WallpaperEngine.updateWallpaperVolume(wallpaperId:volume:)` 内部遍历 `activeWallpapers` 并找到对应 renderer 更新
- 不直接暴露底层字典给外部

```swift
func updateWallpaperVolume(wallpaperId: UUID, volume: Int) {
    for (screenId, (wallpaper, _)) in activeWallpapers {
        guard wallpaper.id == wallpaperId else { continue }
        guard let renderer = renderers[screenId] as? BasicVideoRenderer else { continue }
        let effective = calculateEffectiveVolume(for: wallpaper)
        renderer.setVolume(effective)
    }
}
```

**全局音量更新联动：**
- `WallpaperEngine.updateGlobalVolume(_:)` 需要：
  1. 更新引擎内部 `globalVolume`
  2. 遍历所有活跃视频渲染器，按各自 `volumeOverride` 重算 effectiveVolume 并调用 `setVolume()`

**前端交互统一规则：**
- 预览页音量滑块与色彩页音量滑块**都持久化**
- 滑块显示的是 `baseVolume`（单壁纸音量）
- 前端 `<video>` 实际播放音量 = `baseVolume × globalVolume`

**Bridge 返回壁纸数据变更：**
- `getWallpapers` / `getWallpaperDetail` 返回 `volumeOverride`

### 2.2 音频闪避

**行为：** 当系统存在其他正在播放媒体的应用时，自动静音壁纸；停止后恢复。

**技术路径：MediaRemote.framework**
- 通过私有框架 `MediaRemote.framework` 获取系统 Now Playing 信息
- 适合当前项目的非 App Store 分发场景

**动态加载方式：**
```swift
let handle = dlopen(
    "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
    RTLD_LAZY
)

typealias MRMediaRemoteGetNowPlayingInfoFn = @convention(c) (
    DispatchQueue,
    @escaping ([String: Any]?) -> Void
) -> Void

let fn = unsafeBitCast(dlsym(handle, "MRMediaRemoteGetNowPlayingInfo"),
                       to: MRMediaRemoteGetNowPlayingInfoFn?.self)
```

**监控策略：**
- 1 秒轮询一次
- 如果 `previewOnlyAudio == true`，则**不启动闪避监听**，因为桌面壁纸本来就不出声

**AudioDuckingMonitor：**
- 记录闪避前静音状态 `preDuckingMuteStates`
- 只处理**音频输出屏幕**对应的 renderer，不遍历所有 renderer

**关键回调：**
```swift
fn?(DispatchQueue.main) { [weak self] info in
    guard let self else { return }
    let rate = info?["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0
    let isPlaying = rate > 0
    // 状态切换逻辑...
}
```

**边界条件：**
- 关闭闪避功能：立即停止监听并恢复壁纸音频
- 闪避期间用户手动取消静音：同步更新 `preDuckingMuteStates`
- MediaRemote 加载失败：音频闪避功能降级为不可用，但不影响应用其他部分

### 2.3 音频输出屏幕

**数据模型：**
- `Settings.audioScreenId: String? = nil`

**规则：**
- `nil` → 主屏幕出声
- 指定 screenId → 该屏幕出声
- 其他屏幕强制静音

**设置变更时不要重建渲染器。**
使用轻量方法：`WallpaperEngine.updateAudioScreenMuting(audioScreenId:)`

```swift
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
```

**前端位置：** 音频 Tab 中，放在全局音量下方。

**Bridge：**
- 新增 `getAvailableScreens()` → `[{ id, name, isMain }]`

---

## 子系统 3：轮播调度器

### 核心组件

```swift
@MainActor
final class SlideshowScheduler {
    static let shared = SlideshowScheduler()

    private var timer: Timer?
    private var playlistIds: [UUID] = []
    private var currentIndex: Int = 0
    private var isPaused = false
    private var isAutoSwitching = false
    private weak var modelContext: ModelContext?

    var onSwitchWallpaper: ((Wallpaper) -> Void)?

    func start(context: ModelContext, settings: Settings)
    func stop()
    func next()
    func prev()
    func pause()
    func resume()
    func rebuildPlaylist()
    func updateInterval(_ interval: TimeInterval)
    func onWallpaperChanged(_ wallpaperId: UUID)
}
```

### 3.1 与 AppViewModel 解耦

`SlideshowScheduler` **不直接依赖** `AppViewModel`，而是通过回调输出切换意图：

```swift
SlideshowScheduler.shared.onSwitchWallpaper = { [weak self] wallpaper in
    self?.smartSetWallpaper(wallpaper)
}
```

这样：
- 调度器只负责“决定该切哪张”
- `AppViewModel` 继续负责“如何应用壁纸、更新 UI 状态、持久化 session”

### 3.2 播放列表来源

**数据模型：**
- `Settings.slideshowSource: String = "all"`
- `Settings.slideshowTagId: String? = nil`

来源值：
- `all`
- `favorites`
- `tag`

### 3.3 播放列表构建

**内存策略：** 只保存 `playlistIds`，不长期持有完整 `Wallpaper` 数组。

**标签过滤实现：**
不要依赖不稳定的嵌套 `#Predicate contains`。优先采用：
1. 先 fetch `Tag`
2. 再通过 `tag.wallpapers` 取到结果

```swift
func buildPlaylist(context: ModelContext, settings: Settings) {
    let wallpapers: [Wallpaper]
    switch settings.slideshowSource {
    case "favorites":
        let descriptor = FetchDescriptor<Wallpaper>(predicate: #Predicate { $0.isFavorite == true })
        wallpapers = (try? context.fetch(descriptor)) ?? []
    case "tag":
        if let tagId = settings.slideshowTagId,
           let tagUUID = UUID(uuidString: tagId) {
            let tagDescriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.id == tagUUID })
            let tag = try? context.fetch(tagDescriptor).first
            wallpapers = tag??.wallpapers ?? []
        } else {
            wallpapers = []
        }
    default:
        let descriptor = FetchDescriptor<Wallpaper>()
        wallpapers = (try? context.fetch(descriptor)) ?? []
    }

    let sorted = applySorting(wallpapers, order: settings.slideshowOrder)
    playlistIds = sorted.map(\.id)
}
```

### 3.4 播放列表更新触发机制

不依赖 SwiftData 自动通知。
改为在明确的业务入口手动触发：
- 导入壁纸成功后
- 删除壁纸后
- 收藏状态切换后
- 标签增删改后

这些入口都在 `WebBridge` 已有命令处理中，完成数据操作后显式调用：
```swift
SlideshowScheduler.shared.rebuildPlaylist()
```

### 3.5 轮播参数变更响应链

**必须补齐的状态响应：**
- `slideshowEnabled` 变化 → start / stop
- `slideshowInterval` 变化 → updateInterval
- `slideshowSource` 变化 → rebuildPlaylist
- `slideshowOrder` 变化 → rebuildPlaylist
- `slideshowTagId` 变化 → rebuildPlaylist

**WebBridge：**
```swift
if settings.slideshowEnabled != oldSlideshowEnabled {
    settings.slideshowEnabled ? SlideshowScheduler.shared.start(...) : SlideshowScheduler.shared.stop()
}
if settings.slideshowInterval != oldInterval {
    SlideshowScheduler.shared.updateInterval(settings.slideshowInterval)
}
if settings.slideshowSource != oldSource ||
   settings.slideshowOrder != oldOrder ||
   settings.slideshowTagId != oldTagId {
    SlideshowScheduler.shared.rebuildPlaylist()
}
```

### 3.6 轮播逻辑

**顺序模式：**
- 递增索引
- 仅在单屏幕/镜像模式下尝试跳过“当前正在显示的壁纸”

**随机模式：**
- Fisher-Yates shuffle
- 当播放列表数量 > 2 时，下一轮第一张不能等于上一轮最后一张
- 数量 ≤ 2 时不做该限制

**收藏优先：**
- 收藏壁纸在前，其余按 `importDate`

### 3.7 自动切换与手动切换的区分

这是一个关键逻辑点。

**问题：** 如果轮播自动切换后又触发 `onWallpaperChanged()`，会错误地把自动切换当成手动切换，并重置定时器。

**解决：** 使用 `isAutoSwitching` 标志位。

```swift
func next() {
    guard let wallpaper = currentWallpaper() else { return }
    isAutoSwitching = true
    onSwitchWallpaper?(wallpaper)
}

func onWallpaperChanged(_ wallpaperId: UUID) {
    if isAutoSwitching {
        isAutoSwitching = false
        return
    }

    if let index = playlistIds.firstIndex(of: wallpaperId) {
        currentIndex = index
    }
    resetTimer()
}
```

### 3.8 启动与恢复

**启动时机：**
- `AppViewModel.restoreLastSession()` 完成后
- 若 `settings.slideshowEnabled == true`，启动轮播

**初始位置：**
- 若当前正在显示的壁纸在播放列表中，`currentIndex` 指向它
- 否则 `currentIndex = 0`
- 启动轮播时不立即切换，等待首个间隔结束

**modelContext 失效处理：**
- `modelContext` 为 weak 引用
- 若 `next()` / `rebuildPlaylist()` 时发现 `modelContext == nil`，直接 `stop()`，避免调度器进入坏状态

### 3.9 暂停策略交互

**当前选择：** 暂停后恢复时，重新开始一个完整间隔，而不是记住剩余秒数。

**理由：**
- 逻辑简单，用户容易理解
- 轮播间隔最短为 5 分钟，重新计时对体验影响很小

### 3.10 状态展示

- 在播放 Tab 的轮播区块顶部显示：`第 X/Y 张 · 下次切换 mm:ss`
- 在状态行右侧加 `prev / next` 小按钮
- 倒计时精度：
  - 前端本地每秒递减显示
  - 每 30 秒向后端重新同步一次状态，避免累计漂移

bridge 新增：
- `getSlideshowStatus()`
- `slideshowPrev()`
- `slideshowNext()`

### 3.11 播放列表为空

- 后端不启动 timer
- 前端显示提示：`播放列表为空，请添加壁纸到收藏或选择其他来源`

---

## WebBridge 需要同步修改的点

### 1. `applySettingsUpdate(settings, from:)`
必须新增以下字段解析：
- `loopMode`
- `randomStartPosition`
- `audioScreenId`
- `slideshowSource`
- `slideshowTagId`

### 2. `serializeSettings(_:)`
必须返回以上新增字段，否则前端无法正确初始化。

### 3. `getWallpapers` / `serializeWallpaper(_:)`
必须返回：
- `volumeOverride`

---

## Settings 迁移与默认值

因为本次给 `Settings` 新增了多个非可选字段，必须在 `init` 中提供默认值，确保 SwiftData 可平滑迁移：

```swift
init(
    // 现有参数...
    loopMode: String = "loop",
    randomStartPosition: Bool = false,
    slideshowSource: String = "all",
    slideshowTagId: String? = nil,
    audioScreenId: String? = nil
) {
    self.loopMode = loopMode
    self.randomStartPosition = randomStartPosition
    self.slideshowSource = slideshowSource
    self.slideshowTagId = slideshowTagId
    self.audioScreenId = audioScreenId
    // ...
}
```

---

## Bridge 方法新增/变更

### 新增

| 方法 | 用途 |
|------|------|
| `setWallpaperVolume` | 设置单壁纸音量 |
| `getAvailableScreens` | 获取可选音频输出屏幕 |
| `getSlideshowStatus` | 获取轮播状态 |
| `slideshowPrev` | 手动上一张 |
| `slideshowNext` | 手动下一张 |

### 变更

| 方法 | 变更内容 |
|------|----------|
| `getWallpapers` | 返回 `volumeOverride` |
| `getSettings` | 返回 `loopMode` / `randomStartPosition` / `audioScreenId` / `slideshowSource` / `slideshowTagId` |
| `updateSettings` | 细粒度处理 `playbackRate / loopMode / volume / ducking / slideshow* / audioScreenId` |

---

## WallpaperEngine 新增方法

```swift
func updateAudioConfig(volume: Int, muted: Bool, previewOnly: Bool, rate: Double)
func updatePlaybackRate(_ rate: Double)
func updateGlobalVolume(_ volume: Int)
func updateMutingPolicy(defaultMuted: Bool, previewOnly: Bool)
func updateAudioScreenMuting(audioScreenId: String?)
func updateWallpaperVolume(wallpaperId: UUID, volume: Int)
func enumerateRenderers(_ block: (String, WallpaperRenderer) -> Void)
func enumerateAudioRenderer(_ block: (String, BasicVideoRenderer) -> Void)
var activeWallpaperIds: Set<UUID>
```

注：`updateAudioConfig` 保留用于启动恢复和批量写入内部状态；运行时设置变更优先走细粒度方法。

---

## 不在本次范围

- 过渡效果（淡入淡出、Ken Burns）
- 单壁纸循环模式覆盖
- 定时壁纸
- 音频可视化器
- 轮播历史记录
- 记忆暂停前剩余轮播时间

---

## 实现优先级

**P0：**
1. 播放速率即时生效
2. 循环模式 + 重建链路
3. 单壁纸音量持久化 + 全局音量联动
4. 音频输出屏幕
5. 轮播调度器核心逻辑 + 参数变更响应链
6. WebBridge 新字段序列化 / 反序列化

**P1：**
7. 随机起始位置
8. 音频闪避
9. 预览页进度条
10. 轮播状态展示 + prev/next

**P2：**
11. 壁纸卡片音量 badge
