// Sources/ViewModels/PreviewViewModel.swift
import Foundation
import Observation

@Observable
@MainActor
final class PreviewViewModel {

    // MARK: - State

    var wallpaper: Wallpaper?
    var isPlaying: Bool = false
    var currentTime: Double = 0
    var duration: Double = 0
    var volume: Int = 100
    var isMuted: Bool = false
    var playbackRate: Double = 1.0

    // MARK: - Actions

    func load(_ wallpaper: Wallpaper) {
        self.wallpaper = wallpaper
        self.currentTime = 0
        self.duration = wallpaper.duration ?? 0
        self.isPlaying = false
    }

    func play() {
        isPlaying = true
    }

    func pause() {
        isPlaying = false
    }

    func togglePlayback() {
        isPlaying ? pause() : play()
    }

    func seek(to time: Double) {
        currentTime = min(max(time, 0), duration)
    }

    func setVolume(_ value: Int) {
        volume = min(max(value, 0), 100)
    }

    func toggleMute() {
        isMuted.toggle()
    }

    func setAsWallpaper() {
        guard let wallpaper else { return }
        let url = URL(fileURLWithPath: wallpaper.filePath)
        Task {
            try? await RenderPipeline.shared.setWallpaper(url: url)
            // 将当前映射写入 RestoreManager（默认对所有屏幕）
            var mapping: [String: UUID] = [:]
            for screen in DisplayManager.shared.availableScreens {
                mapping[screen.id] = wallpaper.id
            }
            RestoreManager.shared.saveSession(mapping: mapping)
        }
    }
}
