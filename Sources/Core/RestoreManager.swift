import Foundation
import SwiftData
import AppKit

/// 启动恢复管理器
@MainActor
final class RestoreManager {
    static let shared = RestoreManager()
    private let key = "activeWallpaperMapping"

    private init() {}

    /// 保存当前会话（screenID -> wallpaper UUID）
    func saveSession(mapping: [String: UUID]) {
        let dict = mapping.mapValues { $0.uuidString }
        UserDefaults.standard.set(dict, forKey: key)
    }

    /// 加载持久化映射
    func loadSession() -> [String: UUID] {
        guard let dict = UserDefaults.standard.dictionary(forKey: key) as? [String: String] else {
            return [:]
        }
        var mapping: [String: UUID] = [:]
        for (screenID, uuidString) in dict {
            if let uuid = UUID(uuidString: uuidString) {
                mapping[screenID] = uuid
            }
        }
        return mapping
    }

    /// 恢复上次会话 — 使用 RenderPipeline 设置壁纸
    func restoreSession(context: ModelContext, displayManager: DisplayManager) async {
        let mapping = loadSession()
        guard !mapping.isEmpty else { return }

        // 恢复前同步渲染配置
        let preferencesStore = PreferencesStore(modelContext: context)
        let settings = (try? preferencesStore.fetchSettings()) ?? Settings()

        // 应用壁纸透明度
        RenderPipeline.shared.updateWallpaperOpacity(settings.wallpaperOpacity)

        for screen in displayManager.availableScreens {
            guard let wallpaperID = mapping[screen.id] else { continue }
            let descriptor = FetchDescriptor<Wallpaper>(
                predicate: #Predicate { $0.id == wallpaperID }
            )
            do {
                if let wallpaper = try context.fetch(descriptor).first {
                    let url = URL(fileURLWithPath: wallpaper.filePath)
                    try await RenderPipeline.shared.setWallpaper(url: url, screenId: screen.id)
                }
            } catch {
                continue
            }
        }
    }
}
