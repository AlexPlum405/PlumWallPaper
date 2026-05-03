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
        NotificationCenter.default.post(name: .plumOpenMainWindow, object: nil)
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }

    func openLibrary() {
        openMainWindow()
        NotificationCenter.default.post(name: .plumSwitchMainTab, object: MainTab.myLibrary.rawValue)
    }

    func openLaboratory() {
        NotificationCenter.default.post(name: .plumOpenLaboratory, object: nil)
        openMainWindow()
    }

    func nextWallpaper() {
        SlideshowScheduler.shared.next()
    }

    func openFeedback() {
        if let url = URL(string: "mailto:feedback@plumstudio.art?subject=PlumWallPaper%20Feedback") {
            NSWorkspace.shared.open(url)
        }
    }

    func quit() {
        RenderPipeline.shared.cleanup()
        NSApp.terminate(nil)
    }
}
