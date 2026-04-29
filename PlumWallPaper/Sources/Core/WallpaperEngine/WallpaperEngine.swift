import Foundation
import AppKit
import AVFoundation

/// 壁纸引擎（第一版）
@MainActor
final class WallpaperEngine {
    static let shared = WallpaperEngine()

    private var renderers: [String: WallpaperRenderer] = [:]
    private var activeWallpapers: [String: (Wallpaper, ScreenInfo)] = [:]
    private let desktopBridge = DesktopBridge()
    private var savedDesktopURLs: [String: URL] = [:]  // 保存原始桌面壁纸以便恢复

    // 渲染配置（由 WebBridge 在设置变更时更新）
    var activeColorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.displayP3) ?? CGColorSpace(name: CGColorSpace.sRGB)!
    var performanceMode: Bool = true
    var globalVolume: Float = 0.5  // 0.0 - 1.0
    var defaultMuted: Bool = false
    var previewOnlyAudio: Bool = false
    var playbackRate: Float = 1.0  // 0.5 - 2.0
    var wallpaperOpacity: Float = 1.0  // 0.5 - 1.0
    var fpsLimit: Int = 0  // 0 = unlimited
    var loopMode: String = "loop"  // "loop" | "once"
    var audioScreenId: String? = nil  // 指定音频输出屏幕，nil = 主屏幕
    var randomStartPosition: Bool = false

    private init() {}

    private lazy var blackImageURL: URL = {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("plum_black_bg.png")
        if !FileManager.default.fileExists(atPath: url.path) {
            let size = NSSize(width: 64, height: 64)
            let image = NSImage(size: size)
            image.lockFocus()
            NSColor.black.setFill()
            NSRect(origin: .zero, size: size).fill()
            image.unlockFocus()
            if let tiff = image.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff),
               let png = rep.representation(using: .png, properties: [:]) {
                try? png.write(to: url)
            }
        }
        return url
    }()

    private func setBlackDesktop(for screen: NSScreen, screenId: String) {
        if savedDesktopURLs[screenId] == nil {
            savedDesktopURLs[screenId] = NSWorkspace.shared.desktopImageURL(for: screen)
        }
        try? desktopBridge.setDesktopImage(blackImageURL, for: screen)
    }

    private func restoreDesktop(for screen: NSScreen, screenId: String) {
        if let original = savedDesktopURLs.removeValue(forKey: screenId) {
            try? desktopBridge.setDesktopImage(original, for: screen)
        }
    }

    /// 更新渲染配置
    func updateRenderingConfig(colorSpace: ColorSpace, performanceMode: Bool) {
        self.activeColorSpace = colorSpace.cgColorSpace
        self.performanceMode = performanceMode
    }

    /// 更新音频配置
    func updateAudioConfig(volume: Int, muted: Bool, previewOnly: Bool, rate: Double) {
        self.globalVolume = Float(volume) / 100.0
        self.defaultMuted = muted
        self.previewOnlyAudio = previewOnly
        self.playbackRate = Float(rate)
    }

    /// 更新播放配置（循环模式 / 随机起始位置）
    func updatePlaybackConfig(loopMode: String, randomStartPosition: Bool) {
        self.loopMode = loopMode
        self.randomStartPosition = randomStartPosition
    }

    /// 更新壁纸不透明度
    func updateWallpaperOpacity(_ opacity: Int) {
        self.wallpaperOpacity = Float(opacity) / 100.0
        // 更新所有活跃窗口的透明度
        for renderer in renderers.values {
            if let videoRenderer = renderer as? BasicVideoRenderer {
                videoRenderer.setOpacity(wallpaperOpacity)
            }
        }
    }

    /// 更新 FPS 上限
    func updateFPSLimit(_ limit: Int) {
        self.fpsLimit = limit
        PerformanceMonitor.shared.fpsLimit = limit
        for renderer in renderers.values {
            if let videoRenderer = renderer as? BasicVideoRenderer {
                videoRenderer.setFPSLimit(limit)
            }
        }
    }

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
    func updateMutingPolicy(defaultMuted: Bool, previewOnly: Bool, audioScreenId: String?) {
        self.defaultMuted = defaultMuted
        self.previewOnlyAudio = previewOnly
        updateAudioScreenMuting(audioScreenId: audioScreenId)
    }

    /// 细粒度：更新音频输出屏幕静音状态（不重建渲染器）
    func updateAudioScreenMuting(audioScreenId: String?) {
        self.audioScreenId = audioScreenId
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
        for (key, renderer) in renderers { block(key, renderer) }
    }

    /// 枚举所有视频渲染器
    func enumerateAudioRenderer(_ block: (String, BasicVideoRenderer) -> Void) {
        for (key, renderer) in renderers {
            if let video = renderer as? BasicVideoRenderer { block(key, video) }
        }
    }

    /// 当前所有屏幕正在显示的壁纸 ID
    var activeWallpaperIds: Set<UUID> {
        Set(activeWallpapers.values.map { $0.0.id })
    }

    /// 重载所有活跃渲染器（用于设置变更后即时生效）
    func reloadAllRenderers() {
        let snapshot = activeWallpapers  // 复制字典避免迭代时修改
        for (screenId, (wallpaper, screenInfo)) in snapshot {
            if let old = renderers.removeValue(forKey: screenId) {
                old.stop()
            }
            setWallpaper(wallpaper, for: screenInfo)
        }
    }

    /// 为指定显示器设置壁纸
    func setWallpaper(_ wallpaper: Wallpaper, for screenInfo: ScreenInfo) {
        guard let screen = DisplayManager.shared.screen(for: screenInfo) else { return }
        let key = screenInfo.id

        // 如果是同一壁纸，跳转到开头而不是重建渲染器
        if let (currentWallpaper, _) = activeWallpapers[key], currentWallpaper.id == wallpaper.id {
            if let videoRenderer = renderers[key] as? BasicVideoRenderer {
                videoRenderer.seekToBeginning()
            }
            return
        }

        if let old = renderers.removeValue(forKey: key) {
            old.stop()
        }

        activeWallpapers[key] = (wallpaper, screenInfo)

        // 视频壁纸：将系统桌面替换为纯黑，避免透明度降低时露出原壁纸
        if wallpaper.type == .video {
            setBlackDesktop(for: screen, screenId: key)
        }

        let renderer: WallpaperRenderer
        switch wallpaper.type {
        case .video:
            // 计算音量和静音状态
            let baseVolume = Float(wallpaper.volumeOverride ?? 100) / 100.0
            let effectiveVolume = baseVolume * globalVolume
            let isAudioScreen = (audioScreenId == nil && screenInfo.isMain) || (audioScreenId == key)
            let shouldMute = isAudioScreen ? (defaultMuted || previewOnlyAudio) : true

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
                fpsLimit: fpsLimit,
                randomStartPosition: randomStartPosition
            )
        case .heic, .image:
            renderer = HEICRenderer(wallpaper: wallpaper, screen: screen, desktopBridge: desktopBridge)
        }

        renderers[key] = renderer
        renderer.start()

        // 如果当前处于暂停状态，新渲染器也立即暂停
        if PauseStrategyManager.shared.pauseReason != nil {
            renderer.pause()
        }
    }
    func setWallpaperToAllScreens(_ wallpaper: Wallpaper) {
        for screen in DisplayManager.shared.availableScreens {
            setWallpaper(wallpaper, for: screen)
        }
    }

    /// 全景模式：壁纸横跨所有显示器，每个屏幕显示对应的裁切区域
    func setWallpaperPanorama(_ wallpaper: Wallpaper, screenOrder: [String]?) {
        var screens = DisplayManager.shared.availableScreens
        guard !screens.isEmpty else { return }

        // 按用户拖拽排列的顺序排序
        if let order = screenOrder, !order.isEmpty {
            screens.sort { a, b in
                let ai = order.firstIndex(of: a.id) ?? Int.max
                let bi = order.firstIndex(of: b.id) ?? Int.max
                return ai < bi
            }
        }

        let totalCount = CGFloat(screens.count)
        for (index, screenInfo) in screens.enumerated() {
            guard let screen = DisplayManager.shared.screen(for: screenInfo) else { continue }
            let key = screenInfo.id

            if let old = renderers.removeValue(forKey: key) {
                old.stop()
            }

            activeWallpapers[key] = (wallpaper, screenInfo)

            if wallpaper.type == .video {
                setBlackDesktop(for: screen, screenId: key)
            }

            // 每个屏幕显示 1/N 的横向切片
            let cropRect = CGRect(
                x: CGFloat(index) / totalCount,
                y: 0,
                width: 1.0 / totalCount,
                height: 1.0
            )

            let renderer: WallpaperRenderer
            switch wallpaper.type {
            case .video:
                // 计算音量和静音状态
                let baseVolume = Float(wallpaper.volumeOverride ?? 100) / 100.0
                let effectiveVolume = baseVolume * globalVolume
                let isAudioScreen = (audioScreenId == nil && screenInfo.isMain) || (audioScreenId == key)
                let shouldMute = isAudioScreen ? (defaultMuted || previewOnlyAudio) : true

                renderer = BasicVideoRenderer(
                    wallpaper: wallpaper,
                    screen: screen,
                    colorSpace: activeColorSpace,
                    performanceMode: performanceMode,
                    panoramaCrop: cropRect,
                    volume: effectiveVolume,
                    muted: shouldMute,
                    playbackRate: playbackRate,
                    opacity: wallpaperOpacity,
                    loopMode: loopMode,
                    screenId: key,
                    fpsLimit: fpsLimit,
                    randomStartPosition: randomStartPosition
                )
            case .heic, .image:
                renderer = HEICRenderer(wallpaper: wallpaper, screen: screen, desktopBridge: desktopBridge)
            }

            renderers[key] = renderer
            renderer.start()

            if PauseStrategyManager.shared.pauseReason != nil {
                renderer.pause()
            }
        }
    }
    func pauseAll() {
        renderers.values.forEach { $0.pause() }
    }

    /// 恢复所有渲染
    func resumeAll() {
        renderers.values.forEach { $0.resume() }
    }

    /// 切换全局静音
    func toggleMuteAll() {
        let videoRenderers = renderers.values.compactMap { $0 as? BasicVideoRenderer }
        guard !videoRenderers.isEmpty else { return }
        let shouldMute = !(videoRenderers.first?.isMuted ?? false)
        for renderer in videoRenderers {
            renderer.setMuted(shouldMute)
        }
        defaultMuted = shouldMute
    }

    /// 停止所有渲染
    func stopAll() {
        renderers.values.forEach { $0.stop() }
        renderers.removeAll()
        activeWallpapers.removeAll()
        // 恢复所有显示器的原始桌面壁纸
        for screen in NSScreen.screens {
            let key = String(screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0)
            restoreDesktop(for: screen, screenId: key)
        }
    }

    /// 对正在显示的壁纸应用滤镜
    func applyFilter(_ preset: FilterPreset, to wallpaper: Wallpaper) {
        for renderer in renderers.values {
            renderer.applyFilter(preset)
        }
    }

    /// 获取所有渲染器的平均实际 FPS
    func getActualFPS() -> Int {
        let videoRenderers = renderers.values.compactMap { $0 as? BasicVideoRenderer }
        guard !videoRenderers.isEmpty else { return 0 }
        let totalFPS = videoRenderers.reduce(Float(0)) { $0 + $1.getActualFPS() }
        return Int(totalFPS / Float(videoRenderers.count))
    }

    /// 当前是否有活跃渲染
    var isRendering: Bool {
        return !renderers.isEmpty && renderers.values.contains { renderer in
            if let video = renderer as? BasicVideoRenderer {
                return video.getActualFPS() > 0
            }
            return true
        }
    }
}

/// 视频壁纸渲染器的第一版实现
@MainActor
final class BasicVideoRenderer: WallpaperRenderer {
    private let wallpaper: Wallpaper
    private let screen: NSScreen
    private let colorSpace: CGColorSpace
    private let performanceMode: Bool
    private let panoramaCrop: CGRect?
    private var targetVolume: Float
    private var rate: Float
    private var currentFPSLimit: Int
    private let opacity: Float
    let loopMode: String
    let screenId: String
    private let randomStartPosition: Bool
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var hostingWindow: NSWindow?
    private var looper: AVPlayerLooper?
    private var currentItem: AVPlayerItem?
    private var nominalFrameRate: Float = 30
    private var endObserver: NSObjectProtocol?
    private var isMutedStorage: Bool

    init(wallpaper: Wallpaper, screen: NSScreen, colorSpace: CGColorSpace, performanceMode: Bool, panoramaCrop: CGRect? = nil, volume: Float = 0.5, muted: Bool = false, playbackRate: Float = 1.0, opacity: Float = 1.0, loopMode: String = "loop", screenId: String = "", fpsLimit: Int = 0, randomStartPosition: Bool = false) {
        self.wallpaper = wallpaper
        self.screen = screen
        self.colorSpace = colorSpace
        self.performanceMode = performanceMode
        self.panoramaCrop = panoramaCrop
        self.targetVolume = volume
        self.isMutedStorage = muted
        self.rate = playbackRate
        self.opacity = opacity
        self.loopMode = loopMode
        self.screenId = screenId
        self.currentFPSLimit = fpsLimit
        self.randomStartPosition = randomStartPosition
    }

    // MARK: - Playback Control

    func setPlaybackRate(_ newRate: Float) {
        self.rate = newRate
        applyEffectiveRate()
    }

    func setVolume(_ volume: Float) {
        self.targetVolume = volume
        applyEffectiveVolume()
    }

    func setMuted(_ muted: Bool) {
        self.isMutedStorage = muted
        applyEffectiveVolume()
    }

    var isMuted: Bool {
        isMutedStorage
    }

    func setFPSLimit(_ limit: Int) {
        self.currentFPSLimit = limit
        applyEffectiveRate()
    }

    private func applyEffectiveRate() {
        guard let player = player else { return }
        if player.timeControlStatus == .paused { return }
        // 根据 FPS 上限调整播放速率，确保实际帧率不超过限制
        if currentFPSLimit > 0 && nominalFrameRate > 0 {
            player.rate = min(rate, Float(currentFPSLimit) / nominalFrameRate * rate)
        } else {
            player.rate = rate
        }
    }

    private func applyEffectiveVolume() {
        guard let player = player else { return }
        player.isMuted = isMutedStorage
        player.volume = isMutedStorage ? 0 : targetVolume
    }

    /// 获取当前实际渲染帧率
    func getActualFPS() -> Float {
        guard let player = player else { return 0 }
        if player.timeControlStatus == .paused { return 0 }
        return player.rate * nominalFrameRate
    }

    func start() {
        let asset = AVAsset(url: URL(fileURLWithPath: wallpaper.filePath))
        let item = AVPlayerItem(asset: asset)

        if let videoTrack = asset.tracks(withMediaType: .video).first {
            self.nominalFrameRate = videoTrack.nominalFrameRate
        }

        // 性能模式：省电模式下限制解码分辨率为 1080p
        if !performanceMode {
            item.preferredMaximumResolution = CGSize(width: 1920, height: 1080)
        }

        if let preset = wallpaper.filterPreset {
            item.videoComposition = FilterEngine.shared.videoComposition(for: asset, preset: preset)
        }
        self.currentItem = item
        let queuePlayer = AVQueuePlayer(playerItem: item)
        self.player = queuePlayer

        // 循环模式处理
        if loopMode == "loop" {
            self.looper = AVPlayerLooper(player: queuePlayer, templateItem: item)

            // 随机起始位置（仅在循环模式下）
            if randomStartPosition {
                let duration = asset.duration.seconds
                if duration > 0 && !duration.isNaN && !duration.isInfinite {
                    let randomTime = CMTime(seconds: Double.random(in: 0..<duration), preferredTimescale: 600)
                    queuePlayer.seek(to: randomTime, toleranceBefore: .zero, toleranceAfter: .zero)
                }
            }
        } else if loopMode == "once" {
            // 单次播放：监听播放结束
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.handlePlaybackFinished()
            }
        }

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.ignoresMouseEvents = true
        window.alphaValue = CGFloat(opacity)

        // 应用色彩空间
        window.colorSpace = NSColorSpace(cgColorSpace: colorSpace)

        let contentView = NSView(frame: CGRect(origin: .zero, size: screen.frame.size))
        contentView.wantsLayer = true
        contentView.autoresizingMask = [.width, .height]
        contentView.layer?.masksToBounds = true
        let layer = AVPlayerLayer(player: queuePlayer)

        if let crop = panoramaCrop {
            // 全景模式：放大 layer 并偏移，只显示对应的裁切区域
            let viewSize = contentView.bounds.size
            let scaledWidth = viewSize.width / crop.width
            let scaledHeight = viewSize.height / crop.height
            layer.frame = CGRect(
                x: -crop.origin.x * scaledWidth,
                y: -crop.origin.y * scaledHeight,
                width: scaledWidth,
                height: scaledHeight
            )
            layer.videoGravity = .resizeAspectFill
        } else {
            layer.frame = contentView.bounds
            layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
            layer.videoGravity = .resizeAspectFill
        }

        contentView.layer?.addSublayer(layer)
        window.setFrame(screen.frame, display: false)
        window.contentView = contentView
        window.orderFrontRegardless()

        self.playerLayer = layer
        self.hostingWindow = window

        applyEffectiveVolume()
        applyEffectiveRate()
    }

    /// 播放结束处理（单次模式）
    private func handlePlaybackFinished() {
        player?.pause()
        NotificationCenter.default.post(
            name: NSNotification.Name("PlumPlaybackFinished"),
            object: nil,
            userInfo: ["screenId": screenId]
        )
    }

    /// 跳转到开头并恢复播放
    func seekToBeginning() {
        player?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        applyEffectiveRate()
    }

    func setOpacity(_ opacity: Float) {
        hostingWindow?.alphaValue = CGFloat(opacity)
    }

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

    func pause() {
        player?.pause()
    }

    func resume() {
        applyEffectiveRate()
    }

    func toggleMute() {
        isMutedStorage.toggle()
        applyEffectiveVolume()
    }

    func applyFilter(_ preset: FilterPreset) {
        guard let item = currentItem else { return }
        let asset = item.asset
        item.videoComposition = FilterEngine.shared.videoComposition(for: asset, preset: preset)
    }

    func removeFilter() {
        currentItem?.videoComposition = nil
    }
}
