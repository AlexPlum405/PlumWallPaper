import Foundation
import SwiftData
import AppKit
import Observation
import CryptoKit

/// 应用主 ViewModel：前后端中介层
@Observable
@MainActor
final class AppViewModel {
    // 后端引用
    let engine = WallpaperEngine.shared
    let display = DisplayManager.shared
    let importer = FileImporter.shared
    let filter = FilterEngine.shared
    let restore = RestoreManager.shared

    // 导入状态
    var isImporting = false
    var importProgress: Double = 0
    var currentImportFileName = ""
    var importErrorMessage: String? = nil

    // 重复确认
    var pendingDuplicates: [URL] = []

    // 壁纸状态
    var activeWallpaperPerScreen: [String: Wallpaper] = [:]

    // 多屏选择信号
    var monitorSelectorRequest: Wallpaper? = nil

    // MARK: - 导入

    /// 主导入入口：先扫描重复，再实际导入
    func importFiles(urls: [URL], context: ModelContext) async {
        let store = WallpaperStore(modelContext: context)
        isImporting = true
        importProgress = 0
        importErrorMessage = nil
        defer { isImporting = false }

        var unique: [URL] = []
        var dupes: [URL] = []

        for url in urls {
            do {
                let tempHash = try await quickHash(url: url)
                if try store.wallpaperExists(fileHash: tempHash) {
                    dupes.append(url)
                } else {
                    unique.append(url)
                }
            } catch {
                continue
            }
        }

        // 先导入不重复的
        await actuallyImport(urls: unique, context: context, allowSuffix: false)

        // 把重复的暂存，等用户确认
        if !dupes.isEmpty {
            pendingDuplicates = dupes
        }
    }

    /// 用户确认重复导入：自动加 (2) 后缀
    func confirmDuplicates(context: ModelContext) async {
        let urls = pendingDuplicates
        pendingDuplicates = []
        await actuallyImport(urls: urls, context: context, allowSuffix: true)
    }

    /// 取消重复导入
    func cancelDuplicates() {
        pendingDuplicates = []
    }

    private func actuallyImport(urls: [URL], context: ModelContext, allowSuffix: Bool) async {
        let store = WallpaperStore(modelContext: context)
        let total = max(urls.count, 1)

        for (idx, url) in urls.enumerated() {
            currentImportFileName = url.lastPathComponent
            do {
                let wallpaper = try await importer.importFile(url: url)
                if allowSuffix {
                    wallpaper.name = uniqueName(base: wallpaper.name, store: store)
                }
                try store.addWallpaper(wallpaper)
            } catch {
                importErrorMessage = "导入失败: \(url.lastPathComponent)"
            }
            importProgress = Double(idx + 1) / Double(total)
        }
    }

    private func quickHash(url: URL) async throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: 1024 * 1024) ?? Data()
        return data.sha256()
    }

    private func uniqueName(base: String, store: WallpaperStore) -> String {
        var candidate = base
        var idx = 2
        while existingNameCount(name: candidate, store: store) > 0 {
            candidate = "\(base) (\(idx))"
            idx += 1
        }
        return candidate
    }

    private func existingNameCount(name: String, store: WallpaperStore) -> Int {
        do {
            let all = try store.fetchAllWallpapers()
            return all.filter { $0.name == name }.count
        } catch {
            return 0
        }
    }

    // MARK: - 设壁纸

    func smartSetWallpaper(_ wallpaper: Wallpaper) {
        if display.availableScreens.count <= 1, let screen = display.availableScreens.first {
            setWallpaper(wallpaper, for: screen)
        } else {
            monitorSelectorRequest = wallpaper
        }
    }

    func setWallpaper(_ wallpaper: Wallpaper, for screen: ScreenInfo) {
        engine.setWallpaper(wallpaper, for: screen)
        activeWallpaperPerScreen[screen.id] = wallpaper
        wallpaper.lastUsedDate = Date()
        persistMapping()
    }

    func setWallpaperToAll(_ wallpaper: Wallpaper) {
        for screen in display.availableScreens {
            engine.setWallpaper(wallpaper, for: screen)
            activeWallpaperPerScreen[screen.id] = wallpaper
        }
        wallpaper.lastUsedDate = Date()
        persistMapping()
    }

    private func persistMapping() {
        let map = activeWallpaperPerScreen.mapValues { $0.id }
        restore.saveSession(mapping: map)
    }

    // MARK: - 滤镜

    func applyFilter(_ preset: FilterPreset, to wallpaper: Wallpaper) {
        engine.applyFilter(preset, to: wallpaper)
    }

    // MARK: - 启动恢复

    func restoreLastSession(context: ModelContext) async {
        await restore.restoreSession(
            context: context,
            displayManager: display,
            wallpaperEngine: engine
        )
        // 把恢复后的状态同步到 activeWallpaperPerScreen
        let mapping = restore.loadSession()
        for (screenID, uuid) in mapping {
            let descriptor = FetchDescriptor<Wallpaper>(
                predicate: #Predicate { $0.id == uuid }
            )
            if let wallpaper = try? context.fetch(descriptor).first {
                activeWallpaperPerScreen[screenID] = wallpaper
            }
        }
    }
}

private extension Data {
    func sha256() -> String {
        let digest = SHA256.hash(data: self)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
