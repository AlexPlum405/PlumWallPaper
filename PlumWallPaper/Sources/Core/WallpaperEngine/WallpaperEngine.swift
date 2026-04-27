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

        // 停止旧 renderer
        renderers[key]?.stop()

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
}

/// 视频壁纸渲染器的第一版实现
final class BasicVideoRenderer: WallpaperRenderer {
    private let wallpaper: Wallpaper
    private let screen: NSScreen
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var hostingWindow: NSWindow?
    private var looper: AVPlayerLooper?

    init(wallpaper: Wallpaper, screen: NSScreen) {
        self.wallpaper = wallpaper
        self.screen = screen
    }

    func start() {
        let asset = AVAsset(url: URL(fileURLWithPath: wallpaper.filePath))
        let item = AVPlayerItem(asset: asset)
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

    func stop() {
        player?.pause()
        looper = nil
        playerLayer?.removeFromSuperlayer()
        hostingWindow?.close()
        hostingWindow = nil
        player = nil
        playerLayer = nil
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        player?.play()
    }

    func applyFilter(_ preset: FilterPreset) {
        // TODO: 第二版接入 FilterEngine
    }

    func removeFilter() {
        // TODO: 第二版接入 FilterEngine
    }
}
