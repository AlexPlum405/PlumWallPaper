// Sources/Engine/RenderPipeline.swift
import Foundation
import AppKit
import Metal

@MainActor
final class RenderPipeline {
    static let shared = RenderPipeline()

    private let device: MTLDevice
    private var renderers: [String: ScreenRenderer] = [:]

    /// 当前全局静音状态（muteAudio 默认语义）
    private(set) var isMuted: Bool = false
    /// 当前 FPS 上限（0 = 不限制）
    private(set) var fpsLimit: Int = 0
    /// 壁纸透明度（0-100）
    private(set) var wallpaperOpacity: Int = 100

    private init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal not supported")
        }
        self.device = device
    }

    func setupRenderers() throws {
        for screen in NSScreen.screens {
            let description = screen.deviceDescription
            let screenNumber = description[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            let screenId = screenNumber?.stringValue ?? screen.localizedName
            let renderer = try ScreenRenderer(screen: screen, screenId: screenId, device: device)
            renderers[screenId] = renderer
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

    // MARK: - 音频控制

    /// 获取每个屏幕的静音状态
    func getAudioMuteStates() -> [String: Bool] {
        var states: [String: Bool] = [:]
        for (id, r) in renderers {
            states[id] = r.isMuted
        }
        return states
    }

    /// 设置静音（可选指定屏幕）
    func setMuted(_ muted: Bool, screenId: String? = nil) {
        if let screenId = screenId, let renderer = renderers[screenId] {
            renderer.setMuted(muted)
        } else {
            isMuted = muted
            renderers.values.forEach { $0.setMuted(muted) }
        }
    }

    // MARK: - FPS / 透明度

    func updateFPSLimit(_ limit: Int) {
        fpsLimit = limit
        renderers.values.forEach { $0.setFPSLimit(limit) }
    }

    func updateWallpaperOpacity(_ opacity: Int) {
        wallpaperOpacity = opacity
        let alpha = CGFloat(max(0, min(100, opacity))) / 100.0
        renderers.values.forEach { $0.setOpacity(alpha) }
    }

    // MARK: - 性能监控

    /// 所有屏幕的实测 FPS 平均值
    var currentFPS: Double {
        let values = renderers.values.map { $0.measuredFPS }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    /// 当前活动壁纸 ID 集合
    var activeWallpaperIds: Set<UUID> {
        Set(renderers.values.compactMap { $0.currentWallpaperId })
    }
}
