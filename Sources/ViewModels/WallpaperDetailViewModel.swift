import Combine
import Foundation
import SwiftData

@MainActor
final class WallpaperDetailViewModel: ObservableObject {
    @Published private(set) var fullResolutionContentURL: URL?
    @Published private(set) var isFavoriteDisplayed = false
    @Published private(set) var isApplying = false
    @Published private(set) var isDownloading = false

    private var activePreviewTaskID: String?

    static func previewTaskID(for wallpaper: Wallpaper) -> String {
        "\(wallpaper.remoteId ?? wallpaper.id.uuidString)|\(wallpaper.filePath)"
    }

    static func url(from path: String) -> URL? {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil { return url }
        return URL(fileURLWithPath: trimmed)
    }

    func contentURL(for wallpaper: Wallpaper) -> URL? {
        let url = fullResolutionContentURL ?? Self.url(from: wallpaper.filePath)
        if url == nil {
            NSLog("[WallpaperDetailViewModel] ⚠️ 无法解析 contentURL, filePath: '\(wallpaper.filePath)', type: \(wallpaper.type), source: \(wallpaper.source)")
        }
        return url
    }

    func posterURL(for wallpaper: Wallpaper) -> URL? {
        wallpaper.thumbnailPath.flatMap { Self.url(from: $0) }
    }

    func resetPreview() {
        activePreviewTaskID = nil
        fullResolutionContentURL = nil
    }

    func prepareFullResolutionPreview(for wallpaper: Wallpaper) async {
        let taskID = Self.previewTaskID(for: wallpaper)
        activePreviewTaskID = taskID

        guard let remoteURL = Self.url(from: wallpaper.filePath), remoteURL.isFileURL == false else {
            fullResolutionContentURL = nil
            if wallpaper.type == .video, let videoURL = contentURL(for: wallpaper) {
                PreviewResourcePipeline.shared.preloadVideo(url: videoURL)
            }
            return
        }

        if let cached = await PreviewResourcePipeline.shared.cachedFullResolutionURL(for: remoteURL) {
            guard isActive(taskID) else { return }
            fullResolutionContentURL = cached
            if wallpaper.type == .video {
                PreviewResourcePipeline.shared.preloadVideo(url: cached)
            }
            return
        }

        if wallpaper.type == .video {
            PreviewResourcePipeline.shared.preloadVideo(url: remoteURL)
        }

        do {
            let cached = try await PreviewResourcePipeline.shared.prepareFullResolutionURL(for: remoteURL)
            guard isActive(taskID) else { return }
            fullResolutionContentURL = cached
            if wallpaper.type == .video {
                PreviewResourcePipeline.shared.preloadVideo(url: cached)
            }
            NSLog("[WallpaperDetailViewModel] ✅ 高清预览缓存就绪: \(cached.lastPathComponent)")
        } catch {
            NSLog("[WallpaperDetailViewModel] ⚠️ 高清预览缓存失败，继续使用远程地址: \(error.localizedDescription)")
        }
    }

    private func isActive(_ taskID: String) -> Bool {
        !Task.isCancelled && activePreviewTaskID == taskID
    }

    func toggleFavorite(for wallpaper: Wallpaper, in modelContext: ModelContext) throws -> Bool {
        let newFavoriteState = try FavoriteService.toggleFavorite(for: wallpaper, in: modelContext)
        wallpaper.isFavorite = newFavoriteState
        isFavoriteDisplayed = newFavoriteState
        NSLog("[WallpaperDetailViewModel] ✅ 收藏状态已保存: \(wallpaper.isFavorite), remoteId: \(wallpaper.remoteId ?? "nil")")
        return newFavoriteState
    }

    func syncFavoriteDisplayState(for wallpaper: Wallpaper, in modelContext: ModelContext) {
        do {
            if let persisted = try FavoriteService.persistedWallpaper(for: wallpaper, in: modelContext) {
                isFavoriteDisplayed = persisted.isFavorite
                wallpaper.isFavorite = persisted.isFavorite
            } else {
                isFavoriteDisplayed = wallpaper.isFavorite
            }
        } catch {
            isFavoriteDisplayed = wallpaper.isFavorite
            NSLog("[WallpaperDetailViewModel] ⚠️ 收藏状态同步失败: \(error.localizedDescription)")
        }
    }

    func downloadWallpaper(_ wallpaper: Wallpaper, in modelContext: ModelContext) async throws -> DetailDownloadResult {
        guard let remoteURL = Self.downloadURL(from: wallpaper.filePath) else {
            return .alreadyLocal
        }

        if let remoteId = wallpaper.remoteId,
           DownloadManager.shared.isAlreadyDownloaded(remoteId: remoteId, context: modelContext) != nil {
            return .alreadyLocal
        }

        isDownloading = true
        defer { isDownloading = false }

        let downloaded = try await DownloadManager.shared.downloadWallpaper(
            item: .local(wallpaper),
            quality: wallpaper.resolution ?? "Original",
            downloadURL: remoteURL,
            context: modelContext
        )
        return .downloaded(downloaded)
    }

    func applyWallpaper(_ wallpaper: Wallpaper, effects: WallpaperRenderEffects, in modelContext: ModelContext) async throws -> DetailApplyResult {
        isApplying = true
        defer { isApplying = false }

        let localResult = try await ensureLocalWallpaperForApply(wallpaper, in: modelContext)
        let localWallpaper = localResult.wallpaper

        if localWallpaper.type == .video {
            let videoURL = URL(fileURLWithPath: localWallpaper.filePath)
            try await RenderPipeline.shared.setWallpaper(url: videoURL, wallpaperId: localWallpaper.id, effects: effects)
        } else {
            let imageURL = URL(fileURLWithPath: localWallpaper.filePath)
            let renderedURL = try WallpaperRenderEffectRenderer.renderImage(sourceURL: imageURL, effects: effects)
            if effects.hasDynamicEnvironment {
                try await RenderPipeline.shared.setImageWallpaper(url: renderedURL, wallpaperId: localWallpaper.id, effects: effects)
            } else {
                RenderPipeline.shared.cleanup()
                try WallpaperSetter.shared.setWallpaper(imageURL: renderedURL)
            }
        }

        return DetailApplyResult(
            wallpaper: localWallpaper,
            downloadedWallpaper: localResult.downloadedWallpaper,
            message: effects.hasDynamicEnvironment ? "已应用基础调校，动态天气/粒子已保存" : "设置成功"
        )
    }

    private func ensureLocalWallpaperForApply(_ wallpaper: Wallpaper, in modelContext: ModelContext) async throws -> DetailLocalWallpaperResult {
        if !Self.isRemotePath(wallpaper.filePath), FileManager.default.fileExists(atPath: wallpaper.filePath) {
            return DetailLocalWallpaperResult(wallpaper: wallpaper, downloadedWallpaper: nil)
        }

        if let remoteId = wallpaper.remoteId,
           let downloaded = DownloadManager.shared.isAlreadyDownloaded(remoteId: remoteId, context: modelContext) {
            return DetailLocalWallpaperResult(wallpaper: downloaded, downloadedWallpaper: nil)
        }

        guard let remoteURL = Self.remoteDownloadURLForApply(wallpaper) else {
            throw NSError(domain: "PlumWallPaper", code: 1, userInfo: [NSLocalizedDescriptionKey: "找不到可下载的远程地址"])
        }

        let downloaded = try await DownloadManager.shared.downloadWallpaper(
            item: .local(wallpaper),
            quality: wallpaper.resolution ?? "Original",
            downloadURL: remoteURL,
            context: modelContext
        )
        return DetailLocalWallpaperResult(wallpaper: downloaded, downloadedWallpaper: downloaded)
    }

    private static func remoteDownloadURLForApply(_ wallpaper: Wallpaper) -> URL? {
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

    private static func downloadURL(from path: String) -> URL? {
        guard let url = URL(string: path), url.scheme != nil else { return nil }
        return url
    }

    private static func isRemotePath(_ path: String) -> Bool {
        guard let url = URL(string: path), let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }
}

enum DetailDownloadResult {
    case alreadyLocal
    case downloaded(Wallpaper)
}

struct DetailApplyResult {
    let wallpaper: Wallpaper
    let downloadedWallpaper: Wallpaper?
    let message: String
}

private struct DetailLocalWallpaperResult {
    let wallpaper: Wallpaper
    let downloadedWallpaper: Wallpaper?
}
