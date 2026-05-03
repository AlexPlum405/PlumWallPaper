// Sources/ViewModels/SettingsViewModel.swift
import Foundation
import AppKit
import SwiftData
import Observation

@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - State

    var settings: Settings?
    var errorMessage: String?

    // MARK: - Dependencies

    private var prefStore: PreferencesStore?
    private var modelContext: ModelContext?

    // MARK: - Init

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.prefStore = PreferencesStore(modelContext: modelContext)
        loadSettings()
        configureRuntimeHooks()
        applyStoredRuntimeSettings()
    }

    // MARK: - Actions

    func loadSettings() {
        guard let prefStore else { return }
        do {
            settings = try prefStore.fetchSettings()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save() {
        guard let prefStore else { return }
        do {
            try prefStore.save()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Convenience mutators

    func setFPSLimit(_ value: Int?) {
        settings?.fpsLimit = value
        PerformanceMonitor.shared.fpsLimit = value ?? 0
        save()
    }

    func setGlobalVolume(_ value: Int) {
        settings?.globalVolume = min(max(value, 0), 100)
        save()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        settings?.launchAtLogin = enabled
        save()
        LaunchAtLoginManager.shared.setEnabled(enabled)
    }

    func setTheme(_ mode: ThemeMode) {
        settings?.themeMode = mode
        save()
        applyTheme(mode)
    }

    func setDisplayTopology(_ topology: DisplayTopology) {
        settings?.displayTopology = topology
        save()
    }

    func setMenuBarEnabled(_ enabled: Bool) {
        settings?.menuBarEnabled = enabled
        save()
        NotificationCenter.default.post(name: .plumMenuBarVisibilityChanged, object: enabled)
    }

    func setLibraryPath(_ path: String) {
        settings?.libraryPath = path
        save()
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    }

    func setColorSpace(_ option: ColorSpaceOption) {
        settings?.colorSpace = option
        save()
    }

    func setThumbnailSize(_ size: ThumbnailSize) {
        settings?.thumbnailSize = size
        save()
    }

    func setAnimationsEnabled(_ enabled: Bool) {
        settings?.animationsEnabled = enabled
        save()
    }

    func setWallpaperOpacity(_ opacity: Int) {
        let clamped = min(max(opacity, 0), 100)
        settings?.wallpaperOpacity = clamped
        save()
        RenderPipeline.shared.updateWallpaperOpacity(clamped)
    }

    func clearCaches() async {
        VideoCacheManager.shared.clearCache()
        URLCache.shared.removeAllCachedResponses()
        try? await CacheService.shared.clearCache()
        ThumbnailGenerator.shared.cleanCacheIfNeeded(threshold: 0)
    }

    func togglePauseStrategy(keyPath: ReferenceWritableKeyPath<Settings, Bool>) {
        guard let settings else { return }
        settings[keyPath: keyPath].toggle()
        save()
        PauseStrategyManager.shared.reevaluate()
    }

    func updatePauseStrategy(_ keyPath: ReferenceWritableKeyPath<Settings, Bool>, _ enabled: Bool) {
        settings?[keyPath: keyPath] = enabled
        save()
        PauseStrategyManager.shared.reevaluate()
    }

    func applySlideshowSettings() {
        guard let settings, let modelContext else { return }
        if settings.slideshowEnabled {
            SlideshowScheduler.shared.start(context: modelContext, settings: settings)
        } else {
            SlideshowScheduler.shared.stop()
        }
    }

    // MARK: - Runtime Wiring

    private func configureRuntimeHooks() {
        GlobalShortcutManager.shared.onNextWallpaper = {
            SlideshowScheduler.shared.next()
        }
        GlobalShortcutManager.shared.onPrevWallpaper = {
            SlideshowScheduler.shared.prev()
        }
        GlobalShortcutManager.shared.onTogglePlayback = {
            PauseStrategyManager.shared.toggleManualPause()
        }
        GlobalShortcutManager.shared.onToggleMute = {
            RenderPipeline.shared.setMuted(!RenderPipeline.shared.isMuted)
        }
        GlobalShortcutManager.shared.onShowWindow = {
            NotificationCenter.default.post(name: .plumOpenMainWindow, object: nil)
        }
        GlobalShortcutManager.shared.onToggleFavorite = { [weak self] in
            self?.toggleActiveWallpaperFavorite()
        }
        GlobalShortcutManager.shared.start()

        SlideshowScheduler.shared.activeWallpaperIdsProvider = {
            RenderPipeline.shared.activeWallpaperIds
        }
        SlideshowScheduler.shared.onSwitchWallpaper = { wallpaper in
            Task { @MainActor in
                await Self.applySlideshowWallpaper(wallpaper)
            }
        }

        PauseStrategyManager.shared.startMonitoring { [weak self] in
            guard let settings = self?.settings else { return [:] }
            return Self.pauseSettingsDictionary(settings)
        }

        PerformanceMonitor.shared.startMonitoring()
    }

    private func applyStoredRuntimeSettings() {
        guard let settings else { return }
        if settings.launchAtLogin != LaunchAtLoginManager.shared.isEnabled {
            LaunchAtLoginManager.shared.setEnabled(settings.launchAtLogin)
        }
        RenderPipeline.shared.updateWallpaperOpacity(settings.wallpaperOpacity)
        PerformanceMonitor.shared.fpsLimit = settings.fpsLimit ?? 0
        applyTheme(settings.themeMode)
        applySlideshowSettings()
    }

    private func applyTheme(_ mode: ThemeMode) {
        switch mode {
        case .auto:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    private func toggleActiveWallpaperFavorite() {
        guard let modelContext else { return }
        let activeId = RenderPipeline.shared.activeWallpaperIds.first
            ?? RestoreManager.shared.loadSession().values.first
        guard let activeId else { return }

        let descriptor = FetchDescriptor<Wallpaper>(
            predicate: #Predicate { $0.id == activeId }
        )
        guard let wallpaper = try? modelContext.fetch(descriptor).first else { return }

        wallpaper.isFavorite.toggle()
        try? modelContext.save()
        SlideshowScheduler.shared.rebuildPlaylist()
    }

    private static func applySlideshowWallpaper(_ wallpaper: Wallpaper) async {
        guard let url = url(from: wallpaper.filePath) else { return }
        do {
            if wallpaper.type == .video {
                try await RenderPipeline.shared.setWallpaper(url: url, wallpaperId: wallpaper.id)
            } else {
                RenderPipeline.shared.cleanup()
                try WallpaperSetter.shared.setWallpaper(imageURL: url)
            }
            SlideshowScheduler.shared.onWallpaperChanged(wallpaper.id)
        } catch {
            NSLog("[SettingsViewModel] 轮播切换失败: \(error.localizedDescription)")
        }
    }

    private static func url(from path: String) -> URL? {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        return URL(fileURLWithPath: trimmed)
    }

    private static func pauseSettingsDictionary(_ settings: Settings) -> [String: Any] {
        [
            "pauseOnBattery": settings.pauseOnBattery,
            "pauseOnFullscreen": settings.pauseOnFullscreen,
            "pauseOnLowBattery": settings.pauseOnLowBattery,
            "pauseOnScreenSharing": settings.pauseOnScreenSharing,
            "pauseOnHighLoad": settings.pauseOnHighLoad,
            "pauseOnLostFocus": settings.pauseOnLostFocus,
            "pauseBeforeSleep": settings.pauseBeforeSleep,
            "pauseOnOcclusion": settings.pauseOnOcclusion,
            "appRules": settings.appRules.map {
                [
                    "bundleIdentifier": $0.bundleIdentifier,
                    "action": $0.action.rawValue,
                    "enabled": $0.enabled
                ]
            }
        ]
    }
}

extension Notification.Name {
    static let plumMenuBarVisibilityChanged = Notification.Name("plumMenuBarVisibilityChanged")
    static let plumOpenMainWindow = Notification.Name("plumOpenMainWindow")
    static let plumSwitchMainTab = Notification.Name("plumSwitchMainTab")
    static let plumOpenLaboratory = Notification.Name("plumOpenLaboratory")
}
