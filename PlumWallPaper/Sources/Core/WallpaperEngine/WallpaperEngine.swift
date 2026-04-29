import Foundation
import AppKit
import AVFoundation

/// 壁纸引擎（第一版）
@MainActor
final class WallpaperEngine {
    static let shared = WallpaperEngine()

    private var renderers: [String: WallpaperRenderer] = [:]
    private var activeWallpapers: [String: (Wallpaper, ScreenInfo)] = [:]  // 保存活跃壁纸信息用于重载
    private let desktopBridge = DesktopBridge()

    // 渲染配置（由 WebBridge 在设置变更时更新）
    var activeColorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
    var performanceMode: Bool = true

    private init() {}

    /// 更新渲染配置
    func updateRenderingConfig(colorSpace: ColorSpace, performanceMode: Bool) {
        self.activeColorSpace = colorSpace.cgColorSpace
        self.performanceMode = performanceMode
    }

    /// 重载所有活跃渲染器（用于设置变更后即时生效）
    func reloadAllRenderers() {
        for (screenId, (wallpaper, screenInfo)) in activeWallpapers {
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

        if let old = renderers.removeValue(forKey: key) {
            old.stop()
        }

        activeWallpapers[key] = (wallpaper, screenInfo)

        let renderer: WallpaperRenderer
        switch wallpaper.type {
        case .video:
            renderer = BasicVideoRenderer(wallpaper: wallpaper, screen: screen, colorSpace: activeColorSpace, performanceMode: performanceMode)
        case .heic:
            renderer = HEICRenderer(wallpaper: wallpaper, screen: screen, desktopBridge: desktopBridge)
        }

        renderers[key] = renderer
        renderer.start()
    }

    /// 应用到所有显示器
    func setWallpaperToAllScreens(_ wallpaper: Wallpaper) {
        for screen in DisplayManager.shared.availableScreens {
            setWallpaper(wallpaper, for: screen)
        }
    }

    /// 全景模式：壁纸横跨所有显示器，每个屏幕显示对应的裁切区域
    func setWallpaperPanorama(_ wallpaper: Wallpaper) {
        let screens = DisplayManager.shared.availableScreens
        guard !screens.isEmpty else { return }

        let totalCount = CGFloat(screens.count)
        for (index, screenInfo) in screens.enumerated() {
            guard let screen = DisplayManager.shared.screen(for: screenInfo) else { continue }
            let key = screenInfo.id

            if let old = renderers.removeValue(forKey: key) {
                old.stop()
            }

            activeWallpapers[key] = (wallpaper, screenInfo)

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
                renderer = BasicVideoRenderer(wallpaper: wallpaper, screen: screen, colorSpace: activeColorSpace, performanceMode: performanceMode, panoramaCrop: cropRect)
            case .heic:
                renderer = HEICRenderer(wallpaper: wallpaper, screen: screen, desktopBridge: desktopBridge)
            }

            renderers[key] = renderer
            renderer.start()
        }
    }

    /// 暂停所有渲染
    func pauseAll() {
        renderers.values.forEach { $0.pause() }
    }

    /// 恢复所有渲染
    func resumeAll() {
        renderers.values.forEach { $0.resume() }
    }

    /// 停止所有渲染
    func stopAll() {
        renderers.values.forEach { $0.stop() }
        renderers.removeAll()
        activeWallpapers.removeAll()
    }

    /// 对正在显示的壁纸应用滤镜
    func applyFilter(_ preset: FilterPreset, to wallpaper: Wallpaper) {
        for renderer in renderers.values {
            renderer.applyFilter(preset)
        }
    }
}

/// 视频壁纸渲染器的第一版实现
final class BasicVideoRenderer: WallpaperRenderer {
    private let wallpaper: Wallpaper
    private let screen: NSScreen
    private let colorSpace: CGColorSpace
    private let performanceMode: Bool
    private let panoramaCrop: CGRect?  // 归一化裁切区域 (0~1)，nil 表示不裁切
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var hostingWindow: NSWindow?
    private var looper: AVPlayerLooper?
    private var currentItem: AVPlayerItem?

    init(wallpaper: Wallpaper, screen: NSScreen, colorSpace: CGColorSpace, performanceMode: Bool, panoramaCrop: CGRect? = nil) {
        self.wallpaper = wallpaper
        self.screen = screen
        self.colorSpace = colorSpace
        self.performanceMode = performanceMode
        self.panoramaCrop = panoramaCrop
    }

    func start() {
        let asset = AVAsset(url: URL(fileURLWithPath: wallpaper.filePath))
        let item = AVPlayerItem(asset: asset)

        // 性能模式：省电模式下限制解码分辨率为 1080p
        if !performanceMode {
            item.preferredMaximumResolution = CGSize(width: 1920, height: 1080)
        }

        if let preset = wallpaper.filterPreset {
            item.videoComposition = FilterEngine.shared.videoComposition(for: asset, preset: preset)
        }
        self.currentItem = item
        let queuePlayer = AVQueuePlayer(playerItem: item)
        self.looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        self.player = queuePlayer

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

        queuePlayer.play()
    }

    func stop() {
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
        player?.play()
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
