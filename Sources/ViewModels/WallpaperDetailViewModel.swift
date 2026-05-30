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
                PreviewResourcePipeline.shared.preloadVideo(url: videoURL, intent: .detailFullResolution)
            }
            return
        }

        if let cached = await PreviewResourcePipeline.shared.cachedFullResolutionURL(for: remoteURL) {
            guard isActive(taskID) else { return }
            fullResolutionContentURL = cached
            if wallpaper.type == .video {
                PreviewResourcePipeline.shared.preloadVideo(url: cached, intent: .detailFullResolution)
            }
            return
        }

        if wallpaper.type == .video {
            PreviewResourcePipeline.shared.preloadVideo(url: remoteURL, intent: .detailFullResolution)
        }

        do {
            let cached = try await PreviewResourcePipeline.shared.prepareFullResolutionURL(for: remoteURL, intent: .detailFullResolution)
            guard isActive(taskID) else { return }
            fullResolutionContentURL = cached
            if wallpaper.type == .video {
                PreviewResourcePipeline.shared.preloadVideo(url: cached, intent: .detailFullResolution)
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
        let result = try WallpaperLibraryStateService.toggleFavorite(for: wallpaper, in: modelContext)
        let newFavoriteState = result.isFavorite
        wallpaper.isFavorite = newFavoriteState
        isFavoriteDisplayed = newFavoriteState
        NSLog("[WallpaperDetailViewModel] ✅ 收藏状态已保存: \(wallpaper.isFavorite), remoteId: \(wallpaper.remoteId ?? "nil")")
        return newFavoriteState
    }

    func syncFavoriteDisplayState(for wallpaper: Wallpaper, in modelContext: ModelContext) {
        let state = WallpaperLibraryStateService.state(for: wallpaper, in: modelContext)
        isFavoriteDisplayed = state.isFavorite
        wallpaper.isFavorite = state.isFavorite
    }

    func downloadWallpaper(_ wallpaper: Wallpaper, in modelContext: ModelContext) async throws -> DetailDownloadResult {
        guard let remoteURL = WallpaperLibraryStateService.remoteDownloadURLForApply(wallpaper) else {
            return .alreadyLocal
        }

        isDownloading = true
        defer { isDownloading = false }

        switch try await WallpaperLibraryStateService.downloadWallpaper(
            item: .local(wallpaper),
            quality: wallpaper.resolution ?? "Original",
            downloadURL: remoteURL,
            context: modelContext
        ) {
        case .alreadyLocal:
            return .alreadyLocal
        case .alreadyQueued:
            throw DownloadError.alreadyInProgress
        case .downloaded(let downloaded):
            return .downloaded(downloaded)
        }
    }

    func applyWallpaper(
        _ wallpaper: Wallpaper,
        effects: WallpaperRenderEffects,
        targetScreenId: String?,
        in modelContext: ModelContext
    ) async throws -> DetailApplyResult {
        isApplying = true
        defer { isApplying = false }

        let localResult = try await WallpaperLibraryStateService.ensureLocalWallpaperForApply(wallpaper, in: modelContext)
        let localWallpaper = localResult.wallpaper

        let renderedURL: URL
        if localWallpaper.type == .image || localWallpaper.type == .heic {
            let imageURL = URL(fileURLWithPath: localWallpaper.filePath)
            renderedURL = try WallpaperRenderEffectRenderer.renderImage(sourceURL: imageURL, effects: effects)
        } else {
            renderedURL = URL(fileURLWithPath: localWallpaper.filePath)
        }

        NSLog("[WallpaperDetailViewModel] 应用壁纸，targetScreenId=\(targetScreenId ?? "nil")")

        let message = try await WallpaperLibraryStateService.applyLocalWallpaper(
            localWallpaper,
            renderedURL: renderedURL,
            effects: effects,
            targetScreenId: targetScreenId,
            in: modelContext
        )

        return DetailApplyResult(
            wallpaper: localWallpaper,
            downloadedWallpaper: localResult.downloadedWallpaper,
            message: effects.hasDynamicEnvironment ? "\(message)，动态天气/粒子已保存" : message
        )
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
