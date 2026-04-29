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

    /// 恢复上次会话
    func restoreSession(
        context: ModelContext,
        displayManager: DisplayManager,
        wallpaperEngine: WallpaperEngine
    ) async {
        let mapping = loadSession()
        guard !mapping.isEmpty else { return }

        // 恢复前同步渲染配置和音频配置
        let preferencesStore = PreferencesStore(modelContext: context)
        let settings = (try? preferencesStore.fetchSettings()) ?? Settings()
        wallpaperEngine.updateRenderingConfig(colorSpace: settings.colorSpace, performanceMode: settings.vSyncEnabled)
        wallpaperEngine.updateAudioConfig(
            volume: settings.globalVolume ?? 50,
            muted: settings.defaultMuted ?? false,
            previewOnly: settings.previewOnlyAudio ?? false,
            rate: settings.playbackRate ?? 1.0
        )
        if let opacity = settings.wallpaperOpacity {
            wallpaperEngine.updateWallpaperOpacity(opacity)
        }
        if let fpsLimit = settings.fpsLimit {
            wallpaperEngine.updateFPSLimit(fpsLimit)
        }

        for screen in displayManager.availableScreens {
            guard let wallpaperID = mapping[screen.id] else { continue }
            let descriptor = FetchDescriptor<Wallpaper>(
                predicate: #Predicate { $0.id == wallpaperID }
            )
            do {
                if let wallpaper = try context.fetch(descriptor).first {
                    wallpaperEngine.setWallpaper(wallpaper, for: screen)
                }
            } catch {
                continue
            }
        }
    }
}
