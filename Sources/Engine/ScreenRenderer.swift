// Sources/Engine/ScreenRenderer.swift
import Foundation
import AppKit
import AVFoundation

@MainActor
final class ScreenRenderer {
    let screenId: String
    let desktopWindow: DesktopWindow

    private var player: AVPlayer { desktopWindow.player }

    /// 当前壁纸 ID (用于 RestoreManager / SlideshowScheduler)
    private(set) var currentWallpaperId: UUID?
    /// 静音状态
    private(set) var isMuted: Bool = false

    init(screen: NSScreen, screenId: String) {
        self.screenId = screenId
        self.desktopWindow = DesktopWindow(screen: screen)
    }

    func setWallpaper(url: URL, wallpaperId: UUID? = nil, effects: WallpaperRenderEffects? = nil) async throws {
        NSLog("[ScreenRenderer] setWallpaper: \(url.lastPathComponent)")

        self.currentWallpaperId = wallpaperId

        desktopWindow.displayVideo()
        desktopWindow.configureEnvironment(effects: effects)

        let playerItem = AVPlayerItem(url: url)
        if let effects,
           let composition = WallpaperRenderEffectRenderer.makeVideoComposition(for: url, effects: effects) {
            playerItem.videoComposition = composition
        }
        player.replaceCurrentItem(with: playerItem)

        // 循环播放
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        player.isMuted = false
        player.volume = 1.0
        isMuted = false

        // 显示窗口
        desktopWindow.alphaValue = 1.0
        desktopWindow.show()

        // 播放
        player.play()
        NSLog("[ScreenRenderer] ✅ player.play() rate=\(player.rate)")
    }

    func setImageWallpaper(url: URL, wallpaperId: UUID? = nil, effects: WallpaperRenderEffects? = nil) async throws {
        NSLog("[ScreenRenderer] setImageWallpaper: \(url.lastPathComponent)")

        self.currentWallpaperId = wallpaperId
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        try desktopWindow.displayImage(url: url)
        desktopWindow.configureEnvironment(effects: effects)

        desktopWindow.alphaValue = 1.0
        desktopWindow.show()
    }

    func updateEnvironment(effects: WallpaperRenderEffects?) {
        desktopWindow.configureEnvironment(effects: effects)
    }

    @objc private func playerDidFinishPlaying() {
        player.seek(to: .zero)
        player.play()
    }

    func pause() { player.pause() }
    func resume() { player.play() }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        player.isMuted = muted
    }

    func setOpacity(_ alpha: CGFloat) {
        desktopWindow.alphaValue = alpha
    }

    func cleanup() {
        NotificationCenter.default.removeObserver(self)
        desktopWindow.configureEnvironment(effects: nil)
        player.pause()
        player.replaceCurrentItem(with: nil)
        desktopWindow.hide()
        desktopWindow.alphaValue = 0
    }
}
