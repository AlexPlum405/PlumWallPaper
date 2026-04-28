import Foundation
import AppKit
import AVFoundation

/// 壁纸引擎（第一版）
@MainActor
final class WallpaperEngine {
    static let shared = WallpaperEngine()

    private var renderers: [String: WallpaperRenderer] = [:]
    private let desktopBridge = DesktopBridge()

    private init() {}

    /// 为指定显示器设置壁纸
    func setWallpaper(_ wallpaper: Wallpaper, for screenInfo: ScreenInfo) {
        guard let screen = DisplayManager.shared.screen(for: screenInfo) else { return }
        let key = screenInfo.id

        if let old = renderers.removeValue(forKey: key) {
            old.stop()
        }

        let renderer: WallpaperRenderer
        switch wallpaper.type {
        case .video:
            renderer = BasicVideoRenderer(wallpaper: wallpaper, screen: screen)
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

        let contentView = NSView(frame: CGRect(origin: .zero, size: screen.frame.size))
        contentView.wantsLayer = true
        contentView.autoresizingMask = [.width, .height]
        let layer = AVPlayerLayer(player: queuePlayer)
        layer.frame = contentView.bounds
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer.videoGravity = .resizeAspectFill
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
