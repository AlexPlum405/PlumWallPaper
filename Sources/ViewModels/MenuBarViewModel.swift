// Sources/ViewModels/MenuBarViewModel.swift
import Foundation
import AppKit
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
        RenderPipeline.shared.resumeAll()
    }

    func stopWallpaper() {
        isWallpaperActive = false
        isPaused = false
        currentWallpaperName = nil
        RenderPipeline.shared.pauseAll()
    }

    func temporaryResume() {
        isPaused = false
        pauseReason = nil
        PauseStrategyManager.shared.resumeTemporarily()
    }

    func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }

    func quit() {
        RenderPipeline.shared.cleanup()
        NSApp.terminate(nil)
    }
}
