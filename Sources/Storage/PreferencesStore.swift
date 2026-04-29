// Sources/Storage/PreferencesStore.swift
import Foundation
import SwiftData

struct PreferencesStore {
    let modelContext: ModelContext

    func fetchSettings() throws -> Settings {
        let descriptor = FetchDescriptor<Settings>()
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        let settings = Settings()
        modelContext.insert(settings)
        try modelContext.save()
        return settings
    }

    func save() throws {
        try modelContext.save()
    }
}
