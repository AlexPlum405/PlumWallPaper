// Sources/ViewModels/MenuBarViewModel.swift
import Foundation
import Observation

@Observable
@MainActor
final class MenuBarViewModel {

    // MARK: - State

    var isWallpaperActive: Bool = false
    var currentWallpaperName: String?
    var isPaused: Bool = false
    var pauseReason: String?
    var fps: Double = 0
    var gpuUsage: Double = 0
    var memoryUsage: Double = 0

    // MARK: - Actions

    func toggleWallpaper() {
        if isWallpaperActive {
            stopWallpaper()
        } else {
            resumeWallpaper()
        }
    }

    func resumeWallpaper() {
        isWallpaperActive = true
        isPaused = false
        pauseReason = nil
        // TODO: call WallpaperEngine to resume
    }

    func stopWallpaper() {
        isWallpaperActive = false
        isPaused = false
        currentWallpaperName = nil
        // TODO: call WallpaperEngine to stop
    }

    func temporaryResume() {
        isPaused = false
        pauseReason = nil
        // TODO: call PauseStrategyManager.shared.temporaryResume()
    }

    func openMainWindow() {
        // TODO: bring main window to front
    }

    func quit() {
        // TODO: cleanup + NSApp.terminate
    }
}
