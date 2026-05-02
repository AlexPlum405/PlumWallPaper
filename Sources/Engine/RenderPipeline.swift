// Sources/Engine/RenderPipeline.swift
import Foundation
import AppKit

@MainActor
final class RenderPipeline {
    static let shared = RenderPipeline()

    private var renderers: [String: ScreenRenderer] = [:]

    /// 当前全局静音状态（muteAudio 默认语义）
    private(set) var isMuted: Bool = false
    /// 壁纸透明度（0-100）
    private(set) var wallpaperOpacity: Int = 100

    private init() {}

    func setupRenderers() {
        NSLog("[RenderPipeline] setupRenderers 开始，屏幕数量: \(NSScreen.screens.count)")
        for screen in NSScreen.screens {
            let description = screen.deviceDescription
            let screenNumber = description[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            let screenId = screenNumber?.stringValue ?? screen.localizedName
            let renderer = ScreenRenderer(screen: screen, screenId: screenId)
            renderers[screenId] = renderer
            NSLog("[RenderPipeline] ✅ 屏幕 \(screenId) 渲染器创建成功")
        }
        NSLog("[RenderPipeline] setupRenderers 完成，渲染器数量: \(renderers.count)")
    }

    func setWallpaper(url: URL, screenId: String? = nil) async throws {
        NSLog("[RenderPipeline] setWallpaper: \(url.lastPathComponent), 渲染器数量: \(renderers.count)")
        if renderers.isEmpty {
            NSLog("[RenderPipeline] ⚠️ 无可用渲染器，尝试重新初始化...")
            setupRenderers()
        }
        if let screenId = screenId, let renderer = renderers[screenId] {
            NSLog("[RenderPipeline] 设置屏幕 \(screenId) 壁纸")
            try await renderer.setWallpaper(url: url)
        } else {
            NSLog("[RenderPipeline] 设置所有屏幕壁纸，共 \(renderers.count) 个")
            for (id, renderer) in renderers {
                NSLog("[RenderPipeline] -> 屏幕 \(id)")
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

    // MARK: - 透明度

    func updateWallpaperOpacity(_ opacity: Int) {
        wallpaperOpacity = opacity
        let alpha = CGFloat(max(0, min(100, opacity))) / 100.0
        renderers.values.forEach { $0.setOpacity(alpha) }
    }

    // MARK: - 性能监控

    /// 当前活动壁纸 ID 集合
    var activeWallpaperIds: Set<UUID> {
        Set(renderers.values.compactMap { $0.currentWallpaperId })
    }
}
