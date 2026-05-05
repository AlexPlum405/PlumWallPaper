import Combine
import Foundation
import SwiftData

@MainActor
final class WallpaperDetailViewModel: ObservableObject {
    @Published private(set) var fullResolutionContentURL: URL?
    @Published private(set) var isFavoriteDisplayed = false

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
}
