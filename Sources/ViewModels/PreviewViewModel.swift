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
        // TODO: connect to WallpaperEngine for real playback
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
        // TODO: call WallpaperEngine.setWallpaper + RestoreManager.saveSession
    }
}
