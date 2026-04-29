import Foundation
import SwiftData
import AppKit
import WebKit
import Observation

enum ImportPhase: Equatable {
    case idle
    case scanning
    case importing
    case duplicateReview
    case completed
    case cancelled
}

struct ImportError: Identifiable {
    let id = UUID()
    let fileName: String
    let message: String
}

struct DuplicateItem: Identifiable {
    let id = UUID()
    let url: URL
    let fileName: String
    let fileSize: Int64
    let existingName: String
}

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
    var importPhase: ImportPhase = .idle
    var importProgress: Double = 0
    var currentImportFileName = ""
    var importErrors: [ImportError] = []
    var importedCount: Int = 0
    var skippedCount: Int = 0

    // 重复确认
    var pendingDuplicates: [DuplicateItem] = []

    // 壁纸状态
    var activeWallpaperPerScreen: [String: Wallpaper] = [:]

    // 多屏选择信号
    var monitorSelectorRequest: Wallpaper? = nil

    // 色彩调节信号
    var colorAdjustRequest: Wallpaper? = nil

    // WebView 引用（供 Bridge 回调使用）
    var webView: WKWebView?

    // 取消标记
    private var importTask: Task<Void, Never>?

    var isImporting: Bool {
        importPhase == .scanning || importPhase == .importing
    }

    var hasErrors: Bool {
        !importErrors.isEmpty
    }

    // MARK: - 导入

    func showColorAdjust(_ wallpaper: Wallpaper) {
        colorAdjustRequest = wallpaper
    }

    func importFiles(urls: [URL], context: ModelContext) {
        importTask?.cancel()
        importTask = Task {
            await performImport(urls: urls, context: context)
        }
    }

    func cancelImport() {
        importTask?.cancel()
        importTask = nil
        importPhase = .cancelled
    }

    private func performImport(urls: [URL], context: ModelContext) async {
        let store = WallpaperStore(modelContext: context)

        importPhase = .scanning
        importProgress = 0
        importErrors = []
        importedCount = 0
        skippedCount = 0
        currentImportFileName = ""

        var unique: [URL] = []
        var dupes: [DuplicateItem] = []

        for (idx, url) in urls.enumerated() {
            if Task.isCancelled { return }
            currentImportFileName = url.lastPathComponent
            importProgress = Double(idx + 1) / Double(urls.count)

            do {
                let tempHash = try await quickHash(url: url)
                if try store.wallpaperExists(fileHash: tempHash) {
                    let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
                    let size = (attrs[.size] as? NSNumber)?.int64Value ?? 0
                    let baseName = url.deletingPathExtension().lastPathComponent
                    let existingName = try findExistingName(fileHash: tempHash, store: store) ?? baseName
                    dupes.append(DuplicateItem(
                        url: url,
                        fileName: url.lastPathComponent,
                        fileSize: size,
                        existingName: existingName
                    ))
                } else {
                    unique.append(url)
                }
            } catch {
                importErrors.append(ImportError(
                    fileName: url.lastPathComponent,
                    message: error.localizedDescription
                ))
            }
        }

        if !unique.isEmpty {
            importPhase = .importing
            await actuallyImport(urls: unique, context: context, allowSuffix: false, store: store)
        }

        // 直接跳过重复文件，不再弹窗确认
        skippedCount += dupes.count

        if importErrors.isEmpty {
            importPhase = .completed
        } else {
            importPhase = .completed
        }
    }

    func confirmDuplicates(context: ModelContext) async {
        let items = pendingDuplicates
        pendingDuplicates = []
        importPhase = .importing
        let urls = items.map { $0.url }
        let store = WallpaperStore(modelContext: context)
        await actuallyImport(urls: urls, context: context, allowSuffix: true, store: store)
        importPhase = .completed
    }

    func cancelDuplicates() {
        skippedCount += pendingDuplicates.count
        pendingDuplicates = []
        importPhase = importErrors.isEmpty ? .completed : .completed
    }

    private func actuallyImport(urls: [URL], context: ModelContext, allowSuffix: Bool, store: WallpaperStore) async {
        let total = max(urls.count, 1)

        for (idx, url) in urls.enumerated() {
            if Task.isCancelled { return }
            currentImportFileName = url.lastPathComponent
            do {
                let wallpaper = try await importer.importFile(url: url)
                if allowSuffix {
                    wallpaper.name = uniqueName(base: wallpaper.name, store: store)
                }
                try store.addWallpaper(wallpaper)
                importedCount += 1
            } catch {
                importErrors.append(ImportError(
                    fileName: url.lastPathComponent,
                    message: error.localizedDescription
                ))
            }
            importProgress = Double(idx + 1) / Double(total)
        }
    }

    private func quickHash(url: URL) async throws -> String {
        return try await importer.quickHash(url: url)
    }

    private func findExistingName(fileHash: String, store: WallpaperStore) throws -> String? {
        return try store.findNameByHash(fileHash)
    }

    private func uniqueName(base: String, store: WallpaperStore) -> String {
        var candidate = base
        var idx = 2
        while (try? store.nameExists(candidate)) ?? false {
            candidate = "\(base) (\(idx))"
            idx += 1
        }
        return candidate
    }

    func resetImportState() {
        importPhase = .idle
        importProgress = 0
        currentImportFileName = ""
        importErrors = []
        importedCount = 0
        skippedCount = 0
        pendingDuplicates = []
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

        // 恢复壁纸后立即评估暂停条件，确保启动时状态正确
        PauseStrategyManager.shared.reevaluate()
    }
}
