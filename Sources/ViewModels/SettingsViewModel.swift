// Sources/ViewModels/SettingsViewModel.swift
import Foundation
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

    // MARK: - Init

    func configure(modelContext: ModelContext) {
        self.prefStore = PreferencesStore(modelContext: modelContext)
        loadSettings()
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
        save()
    }

    func setGlobalVolume(_ value: Int) {
        settings?.globalVolume = min(max(value, 0), 100)
        save()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        settings?.launchAtLogin = enabled
        save()
        // TODO: register/unregister with SMAppService
    }

    func setTheme(_ mode: ThemeMode) {
        settings?.themeMode = mode
        save()
    }

    func setDisplayTopology(_ topology: DisplayTopology) {
        settings?.displayTopology = topology
        save()
    }

    func togglePauseStrategy(keyPath: ReferenceWritableKeyPath<Settings, Bool>) {
        guard let settings else { return }
        settings[keyPath: keyPath].toggle()
        save()
        // TODO: call PauseStrategyManager.shared.reevaluate()
    }
}
