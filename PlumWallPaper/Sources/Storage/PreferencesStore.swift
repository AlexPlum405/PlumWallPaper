//
//  PreferencesStore.swift
//  PlumWallPaper
//
//  Created on 2026-04-28.
//

import Foundation
import SwiftData

/// 应用偏好设置管理器
@Observable
final class PreferencesStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// 获取当前设置（如果没有则创建默认设置）
    func fetchSettings() throws -> Settings {
        let descriptor = FetchDescriptor<Settings>()
        let settings = try modelContext.fetch(descriptor)

        if let existingSettings = settings.first {
            return existingSettings
        }

        // 创建默认设置
        let defaultSettings = Settings()
        modelContext.insert(defaultSettings)
        try modelContext.save()
        return defaultSettings
    }

    /// 更新设置
    func updateSettings() throws {
        try modelContext.save()
    }
}
