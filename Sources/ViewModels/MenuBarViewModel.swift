// Sources/ViewModels/MenuBarViewModel.swift
import Foundation
import AppKit
import SwiftData
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
    var superResolutionEnabled: Bool = false
    var videoEnhancementEnabled: Bool = false
    var statusBarShowFPS: Bool = true
    var statusBarShowMemory: Bool = true
    var statusBarShowGPU: Bool = true

    init() {
        syncFromSettings()
    }

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

    func toggleSuperResolution() {
        guard let settings = currentSettings() else { return }
        settings.superResolutionEnabled.toggle()
        superResolutionEnabled = settings.superResolutionEnabled
        try? currentContext()?.save()
        NotificationCenter.default.post(name: .plumSuperResolutionChanged, object: settings.superResolutionEnabled)
    }

    func toggleVideoEnhancement() {
        guard let settings = currentSettings() else { return }
        settings.videoEnhancementEnabled.toggle()
        videoEnhancementEnabled = settings.videoEnhancementEnabled
        try? currentContext()?.save()
        NotificationCenter.default.post(name: .plumVideoEnhancementChanged, object: settings.videoEnhancementEnabled)
    }

    func syncFromSettings() {
        guard let settings = currentSettings() else { return }
        superResolutionEnabled = settings.superResolutionEnabled
        videoEnhancementEnabled = settings.videoEnhancementEnabled
        statusBarShowFPS = settings.statusBarShowFPS
        statusBarShowMemory = settings.statusBarShowMemory
        statusBarShowGPU = settings.statusBarShowGPU
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

    private func currentContext() -> ModelContext? {
        PlumWallPaperApp.sharedModelContainer.mainContext
    }

    private func currentSettings() -> Settings? {
        guard let context = currentContext() else { return nil }
        let store = PreferencesStore(modelContext: context)
        return try? store.fetchSettings()
    }
}
