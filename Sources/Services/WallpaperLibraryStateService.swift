import Foundation
import SwiftData

struct WallpaperLibraryState {
    let persistedWallpaper: Wallpaper?
    let downloadedWallpaper: Wallpaper?
    let downloadTask: DownloadTask?
    let isFavorite: Bool
    let isDownloaded: Bool
    let isLocal: Bool

    var isDownloadActive: Bool {
        downloadTask?.status == .waiting || downloadTask?.status == .downloading
    }
}

struct WallpaperFavoriteActionResult {
    let isFavorite: Bool
    let wallpaper: Wallpaper?
}

enum WallpaperDownloadActionResult {
    case alreadyLocal(Wallpaper?)
    case alreadyQueued(DownloadTask)
    case downloaded(Wallpaper)
}

struct WallpaperLocalResolutionResult {
    let wallpaper: Wallpaper
    let downloadedWallpaper: Wallpaper?
}

@MainActor
enum WallpaperLibraryStateService {
    static func state(for item: WallpaperPreviewItem, in modelContext: ModelContext) -> WallpaperLibraryState {
        state(for: item.makeWallpaper(), in: modelContext)
    }

    static func state(for wallpaper: Wallpaper, in modelContext: ModelContext) -> WallpaperLibraryState {
        let persisted = try? FavoriteService.persistedWallpaper(for: wallpaper, in: modelContext)
        let favorite = try? favoriteWallpaper(for: wallpaper, in: modelContext)
        let downloaded = downloadedWallpaper(for: wallpaper, in: modelContext)
        let downloadTask = DownloadManager.shared.activeTask(remoteId: wallpaper.remoteId)
        let local = isLocalWallpaper(wallpaper) || downloaded != nil

        return WallpaperLibraryState(
            persistedWallpaper: persisted,
            downloadedWallpaper: downloaded,
            downloadTask: downloadTask,
            isFavorite: favorite != nil || persisted?.isFavorite == true || wallpaper.isFavorite,
            isDownloaded: downloaded != nil || wallpaper.source == .downloaded && isLocalWallpaper(wallpaper),
            isLocal: local
        )
    }

    static func downloadedWallpaper(for wallpaper: Wallpaper, in modelContext: ModelContext) -> Wallpaper? {
        guard let remoteId = wallpaper.remoteId else {
            return wallpaper.source == .downloaded && isLocalWallpaper(wallpaper) ? wallpaper : nil
        }
        return DownloadManager.shared.isAlreadyDownloaded(remoteId: remoteId, context: modelContext)
    }

    static func toggleFavorite(for wallpaper: Wallpaper, in modelContext: ModelContext) throws -> WallpaperFavoriteActionResult {
        let isFavorite = try FavoriteService.toggleFavorite(for: wallpaper, in: modelContext)
        let persisted = try? FavoriteService.persistedWallpaper(for: wallpaper, in: modelContext)
        NotificationCenter.default.post(name: .plumLibraryStateChanged, object: wallpaper.remoteId ?? wallpaper.id.uuidString)
        return WallpaperFavoriteActionResult(isFavorite: isFavorite, wallpaper: persisted)
    }

    static func downloadWallpaper(
        item: WallpaperDisplayItem,
        quality: String,
        downloadURL: URL,
        context: ModelContext
    ) async throws -> WallpaperDownloadActionResult {
        if let remoteId = remoteId(for: item),
           let existing = DownloadManager.shared.isAlreadyDownloaded(remoteId: remoteId, context: context) {
            return .alreadyLocal(existing)
        }
        if let activeTask = DownloadManager.shared.activeTask(remoteId: remoteId(for: item)) {
            return .alreadyQueued(activeTask)
        }

        let downloaded = try await DownloadManager.shared.downloadWallpaper(
            item: item,
            quality: quality,
            downloadURL: downloadURL,
            context: context
        )
        NotificationCenter.default.post(name: .plumLibraryStateChanged, object: downloaded.remoteId ?? downloaded.id.uuidString)
        return .downloaded(downloaded)
    }

    static func ensureLocalWallpaperForApply(
        _ wallpaper: Wallpaper,
        quality: String? = nil,
        in modelContext: ModelContext
    ) async throws -> WallpaperLocalResolutionResult {
        if isLocalWallpaper(wallpaper) {
            return WallpaperLocalResolutionResult(wallpaper: wallpaper, downloadedWallpaper: nil)
        }

        if let downloaded = downloadedWallpaper(for: wallpaper, in: modelContext) {
            return WallpaperLocalResolutionResult(wallpaper: downloaded, downloadedWallpaper: nil)
        }

        guard let remoteURL = remoteDownloadURLForApply(wallpaper) else {
            throw NSError(domain: "PlumWallPaper", code: 1, userInfo: [NSLocalizedDescriptionKey: "找不到可下载的远程地址"])
        }

        switch try await downloadWallpaper(
            item: .local(wallpaper),
            quality: quality ?? wallpaper.resolution ?? "Original",
            downloadURL: remoteURL,
            context: modelContext
        ) {
        case .alreadyLocal(let existing):
            guard let existing else {
                throw NSError(domain: "PlumWallPaper", code: 2, userInfo: [NSLocalizedDescriptionKey: "本地壁纸状态异常"])
            }
            return WallpaperLocalResolutionResult(wallpaper: existing, downloadedWallpaper: nil)
        case .alreadyQueued:
            throw DownloadError.alreadyInProgress
        case .downloaded(let downloaded):
            return WallpaperLocalResolutionResult(wallpaper: downloaded, downloadedWallpaper: downloaded)
        }
    }

    static func applyLocalWallpaper(
        _ wallpaper: Wallpaper,
        renderedURL: URL? = nil,
        effects: WallpaperRenderEffects? = nil,
        targetScreenId: String?,
        in modelContext: ModelContext
    ) async throws -> String {
        let settings = try PreferencesStore(modelContext: modelContext).fetchSettings()
        let message = try await WallpaperTopologyCoordinator.shared.apply(
            wallpaper: wallpaper,
            renderedURL: renderedURL,
            effects: effects,
            settings: settings,
            targetScreenId: targetScreenId
        )
        RestoreManager.shared.saveSession(
            mapping: WallpaperTopologyCoordinator.shared.sessionMapping(
                for: wallpaper.id,
                settings: settings,
                targetScreenId: targetScreenId
            )
        )
        SlideshowScheduler.shared.onWallpaperChanged(wallpaper.id)
        NotificationCenter.default.post(name: .plumLibraryStateChanged, object: wallpaper.remoteId ?? wallpaper.id.uuidString)
        return message
    }

    static func isRemotePath(_ path: String) -> Bool {
        guard let url = URL(string: path), let scheme = url.scheme?.lowercased() else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }

    static func isLocalWallpaper(_ wallpaper: Wallpaper) -> Bool {
        !isRemotePath(wallpaper.filePath) && FileManager.default.fileExists(atPath: wallpaper.filePath)
    }

    static func remoteDownloadURLForApply(_ wallpaper: Wallpaper) -> URL? {
        let preferredPath = highQualityVideoPathForApply(wallpaper) ?? wallpaper.filePath
        guard isRemotePath(preferredPath) else { return nil }
        return URL(string: preferredPath)
    }

    private static func highQualityVideoPathForApply(_ wallpaper: Wallpaper) -> String? {
        guard wallpaper.type == .video,
              let quality = wallpaper.downloadQuality,
              isRemotePath(quality)
        else { return nil }
        return quality
    }

    private static func remoteId(for item: WallpaperDisplayItem) -> String? {
        switch item {
        case .remote(let wallpaper): return wallpaper.id
        case .media(let item): return item.id
        case .local(let wallpaper): return wallpaper.remoteId
        }
    }

    private static func favoriteWallpaper(for wallpaper: Wallpaper, in modelContext: ModelContext) throws -> Wallpaper? {
        let wallpaperId = wallpaper.id
        let idDescriptor = FetchDescriptor<Wallpaper>(
            predicate: #Predicate<Wallpaper> { $0.id == wallpaperId }
        )
        if let exactMatch = try modelContext.fetch(idDescriptor).first, exactMatch.isFavorite {
            return exactMatch
        }

        guard let remoteId = wallpaper.remoteId else { return nil }
        let remoteDescriptor = FetchDescriptor<Wallpaper>(
            predicate: #Predicate<Wallpaper> { $0.remoteId == remoteId },
            sortBy: [SortDescriptor(\.importDate, order: .reverse)]
        )
        return try modelContext.fetch(remoteDescriptor).first { $0.isFavorite }
    }
}

extension Notification.Name {
    static let plumLibraryStateChanged = Notification.Name("plumLibraryStateChanged")
}
