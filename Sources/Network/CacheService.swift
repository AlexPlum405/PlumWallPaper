// Sources/Network/CacheService.swift
import Foundation
import CryptoKit

actor CacheService {
    static let shared = CacheService()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            // 使用临时目录作为回退
            cacheDirectory = fileManager.temporaryDirectory.appendingPathComponent("PlumWallPaper/Cache", isDirectory: true)
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            return
        }
        cacheDirectory = appSupport.appendingPathComponent("PlumWallPaper/Cache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// 生成基于完整 URL 的缓存键（使用 SHA256 哈希）
    private func cacheKey(for url: URL) -> String {
        let urlString = url.absoluteString
        // 使用 SHA256 生成唯一标识符
        let data = Data(urlString.utf8)
        let hash = SHA256.hash(data: data)
        // 取前 16 个字符作为文件名（足够唯一且避免文件名过长）
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined().prefix(16)
        // 保留原始扩展名（如果有）
        let ext = url.pathExtension.isEmpty ? "" : ".\(url.pathExtension)"
        return "\(hashString)\(ext)"
    }

    func cacheImage(_ data: Data, for url: URL) async throws {
        let fileName = cacheKey(for: url)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL)
    }

    func cacheFile(_ data: Data, named fileName: String, in directoryName: String) async throws -> URL {
        let directoryURL = cacheDirectory.appendingPathComponent(directoryName, isDirectory: true)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let fileURL = directoryURL.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    func getCachedImage(for url: URL) -> Data? {
        let fileName = cacheKey(for: url)
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        return try? Data(contentsOf: fileURL)
    }

    func cachedFileURL(named fileName: String, in directoryName: String) -> URL? {
        let fileURL = cacheDirectory
            .appendingPathComponent(directoryName, isDirectory: true)
            .appendingPathComponent(fileName)

        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }

    func clearCache() async throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for file in contents {
            try fileManager.removeItem(at: file)
        }
    }

    var cacheSize: Int {
        let contents = (try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return contents.reduce(0) { total, file in
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + size
        }
    }
}

enum PreviewIntent: String, Sendable {
    case heroImmediate
    case visibleCard
    case hoverIntent
    case detailFullResolution

    var priority: Int {
        switch self {
        case .heroImmediate: return 4
        case .detailFullResolution: return 3
        case .visibleCard: return 2
        case .hoverIntent: return 1
        }
    }

    var allowsFullResolutionDownload: Bool {
        switch self {
        case .detailFullResolution:
            return true
        case .heroImmediate, .visibleCard, .hoverIntent:
            return false
        }
    }

    var isCancellable: Bool {
        switch self {
        case .hoverIntent, .visibleCard:
            return true
        case .heroImmediate, .detailFullResolution:
            return false
        }
    }

    var videoPreloadLimit: Int {
        switch self {
        case .heroImmediate:
            return 3
        case .detailFullResolution:
            return 2
        case .visibleCard:
            return 6
        case .hoverIntent:
            return 1
        }
    }
}

actor FullResolutionPreviewCache {
    static let shared = FullResolutionPreviewCache()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private var activeTasks: [URL: Task<URL, Error>] = [:]
    private var activeTaskIntents: [URL: PreviewIntent] = [:]
    private let maxCacheBytes: Int64 = 5 * 1024 * 1024 * 1024
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60

    private init() {
        let fm = FileManager.default
        let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fm.temporaryDirectory
        cacheDirectory = caches.appendingPathComponent("PlumWallPaper/FullResolutionPreviews", isDirectory: true)
        try? fm.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func cachedURL(for remoteURL: URL) -> URL? {
        let fileURL = cacheURL(for: remoteURL)
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        touch(fileURL)
        return fileURL
    }

    func localURL(for remoteURL: URL, intent: PreviewIntent = .detailFullResolution) async throws -> URL {
        if let cached = cachedURL(for: remoteURL) {
            return cached
        }

        if let task = activeTasks[remoteURL] {
            return try await task.value
        }

        let destinationURL = cacheURL(for: remoteURL)
        let task = downloadTask(remoteURL: remoteURL, destinationURL: destinationURL)

        activeTasks[remoteURL] = task
        activeTaskIntents[remoteURL] = intent
        do {
            let url = try await task.value
            await clearFinishedTask(for: remoteURL)
            return url
        } catch {
            await clearFinishedTask(for: remoteURL)
            throw error
        }
    }

    func prefetch(remoteURL: URL, intent: PreviewIntent = .detailFullResolution) {
        guard intent.allowsFullResolutionDownload else {
            _ = cachedURL(for: remoteURL)
            return
        }
        guard cachedURL(for: remoteURL) == nil, activeTasks[remoteURL] == nil else { return }
        let destinationURL = cacheURL(for: remoteURL)
        activeTasks[remoteURL] = downloadTask(remoteURL: remoteURL, destinationURL: destinationURL)
        activeTaskIntents[remoteURL] = intent
    }

    func cancel(remoteURL: URL) {
        guard let intent = activeTaskIntents[remoteURL], intent.isCancellable else { return }
        activeTasks[remoteURL]?.cancel()
        activeTasks[remoteURL] = nil
        activeTaskIntents[remoteURL] = nil
    }

    func clearCache() async throws {
        for task in activeTasks.values {
            task.cancel()
        }
        activeTasks.removeAll()
        activeTaskIntents.removeAll()

        guard fileManager.fileExists(atPath: cacheDirectory.path) else { return }
        let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for file in files {
            try? fileManager.removeItem(at: file)
        }
    }

    var cacheSize: Int64 {
        let files = (try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return files.reduce(Int64(0)) { total, file in
            let size = Int64((try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
            return total + size
        }
    }

    private func clearFinishedTask(for remoteURL: URL) async {
        activeTasks[remoteURL] = nil
        activeTaskIntents[remoteURL] = nil
    }

    private func downloadTask(remoteURL: URL, destinationURL: URL) -> Task<URL, Error> {
        Task { [cacheDirectory, fileManager] in
            defer { Task { await self.clearFinishedTask(for: remoteURL) } }

            let tempURL = cacheDirectory.appendingPathComponent("\(UUID().uuidString).download")

            var request = URLRequest(url: remoteURL)
            request.timeoutInterval = 30
            request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
            request.setValue(Self.acceptHeader(for: remoteURL), forHTTPHeaderField: "Accept")
            if let referer = Self.referer(for: remoteURL) {
                request.setValue(referer, forHTTPHeaderField: "Referer")
            }

            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 15 * 60
            config.waitsForConnectivity = true
            config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            let session = URLSession(configuration: config)

            let (downloadedURL, response) = try await session.download(for: request)
            try Task.checkCancellation()
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }

            try? fileManager.removeItem(at: tempURL)
            try fileManager.moveItem(at: downloadedURL, to: tempURL)
            try? fileManager.removeItem(at: destinationURL)
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            await self.cleanupIfNeeded()
            return destinationURL
        }
    }

    private func cacheURL(for remoteURL: URL) -> URL {
        let data = Data(remoteURL.absoluteString.utf8)
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let ext = normalizedExtension(for: remoteURL)
        return cacheDirectory.appendingPathComponent(hash).appendingPathExtension(ext)
    }

    private func normalizedExtension(for url: URL) -> String {
        let ext = url.pathExtension.trimmingCharacters(in: .whitespacesAndNewlines)
        if !ext.isEmpty { return ext }
        return "preview"
    }

    private func touch(_ fileURL: URL) {
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: fileURL.path)
    }

    private func cleanupIfNeeded() async {
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        let now = Date()
        for file in files {
            let values = try? file.resourceValues(forKeys: [.contentModificationDateKey])
            if let modified = values?.contentModificationDate,
               now.timeIntervalSince(modified) > maxCacheAge {
                try? fileManager.removeItem(at: file)
            }
        }

        let remaining = (try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        var entries: [(url: URL, size: Int64, modified: Date)] = remaining.compactMap { file in
            guard let values = try? file.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]) else { return nil }
            return (file, Int64(values.fileSize ?? 0), values.contentModificationDate ?? .distantPast)
        }

        var total = entries.reduce(Int64(0)) { $0 + $1.size }
        guard total > maxCacheBytes else { return }

        entries.sort { $0.modified < $1.modified }
        for entry in entries where total > maxCacheBytes {
            try? fileManager.removeItem(at: entry.url)
            total -= entry.size
        }
    }

    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"

    private static func acceptHeader(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        if ["mp4", "mov", "m4v", "webm"].contains(ext) {
            return "video/mp4,video/*;q=0.9,*/*;q=0.5"
        }
        return "image/avif,image/webp,image/jpeg,image/png,image/*;q=0.9,*/*;q=0.5"
    }

    private static func referer(for url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }
        if host.contains("wallhaven.cc") || host.contains("w.wallhaven.cc") { return "https://wallhaven.cc/" }
        if host.contains("pexels.com") { return "https://www.pexels.com/" }
        if host.contains("pixabay.com") { return "https://pixabay.com/" }
        if host.contains("unsplash.com") { return "https://unsplash.com/" }
        if host.contains("steam") { return "https://steamcommunity.com/" }
        if host.contains("desktophut.com") { return "https://www.desktophut.com/" }
        if host.contains("motionbgs.com") { return "https://motionbgs.com/" }
        return nil
    }
}

final class PreviewResourcePipeline {
    static let shared = PreviewResourcePipeline()

    private init() {}

    func previewVideoURL(for item: MediaItem) -> URL? {
        item.previewVideoURL ?? item.fullVideoURL
    }

    func fullResolutionURL(for item: MediaItem) -> URL? {
        item.fullVideoURL ?? item.previewVideoURL
    }

    func fullResolutionURL(for item: WallpaperPreviewItem) -> URL? {
        if item.type == .video,
           let downloadQuality = item.downloadQuality,
           let qualityURL = Self.remoteURL(from: downloadQuality) {
            return qualityURL
        }
        return item.contentURL.flatMap(Self.remoteURL)
    }

    func fullResolutionURL(for wallpaper: RemoteWallpaper) -> URL? {
        wallpaper.fullImageURL.flatMap(Self.remoteURL)
    }

    func cachedFullResolutionURL(for remoteURL: URL) async -> URL? {
        await FullResolutionPreviewCache.shared.cachedURL(for: remoteURL)
    }

    func prepareFullResolutionURL(for remoteURL: URL, intent: PreviewIntent = .detailFullResolution) async throws -> URL {
        try await FullResolutionPreviewCache.shared.localURL(for: remoteURL, intent: intent)
    }

    func prefetchFullResolution(url remoteURL: URL, intent: PreviewIntent = .detailFullResolution) async {
        await FullResolutionPreviewCache.shared.prefetch(remoteURL: remoteURL, intent: intent)
    }

    func prefetchFullResolution(for item: WallpaperPreviewItem, intent: PreviewIntent = .detailFullResolution) async {
        guard let url = fullResolutionURL(for: item) else { return }
        await prefetchFullResolution(url: url, intent: intent)
    }

    func prefetchFullResolution(for item: MediaItem, intent: PreviewIntent = .detailFullResolution) async {
        guard let url = fullResolutionURL(for: item) else { return }
        await prefetchFullResolution(url: url, intent: intent)
    }

    func prefetchFullResolution(for wallpaper: RemoteWallpaper, intent: PreviewIntent = .detailFullResolution) async {
        guard let url = fullResolutionURL(for: wallpaper) else { return }
        await prefetchFullResolution(url: url, intent: intent)
    }

    func preheatPreview(for item: WallpaperPreviewItem, intent: PreviewIntent = .visibleCard) {
        guard item.type == .video, let url = item.contentURL else { return }
        if intent == .hoverIntent,
           !url.isFileURL,
           item.downloadQuality == url.absoluteString {
            return
        }
        preloadVideo(url: url, intent: intent)
    }

    func preheatPreview(for item: MediaItem, intent: PreviewIntent = .visibleCard) {
        preloadVideo(for: item, preferFullResolution: false, intent: intent)
    }

    func cancelPreview(url: URL) {
        VideoPreloader.shared.cancelPreload(url: url)
        Task {
            await FullResolutionPreviewCache.shared.cancel(remoteURL: url)
        }
    }

    func cancelPreview(for item: WallpaperPreviewItem) {
        if let url = item.contentURL {
            cancelPreview(url: url)
        }
        if let url = fullResolutionURL(for: item), url != item.contentURL {
            cancelPreview(url: url)
        }
    }

    func cancelPreview(for item: MediaItem) {
        if let url = previewVideoURL(for: item) {
            cancelPreview(url: url)
        }
        if let url = fullResolutionURL(for: item), url != previewVideoURL(for: item) {
            cancelPreview(url: url)
        }
    }

    func cancelPreview(for wallpaper: RemoteWallpaper) {
        guard let url = fullResolutionURL(for: wallpaper) else { return }
        cancelPreview(url: url)
    }

    func preloadVideo(url: URL, intent: PreviewIntent = .visibleCard) {
        VideoPreloader.shared.preload(url: url, priority: intent.priority)
    }

    func preloadVideo(for item: MediaItem, preferFullResolution: Bool = false, intent: PreviewIntent = .visibleCard) {
        let url = preferFullResolution ? fullResolutionURL(for: item) : previewVideoURL(for: item)
        guard let url else { return }
        preloadVideo(url: url, intent: intent)
    }

    func preloadVideo(for item: WallpaperPreviewItem, intent: PreviewIntent = .visibleCard) {
        let candidateURL = intent == .detailFullResolution ? fullResolutionURL(for: item) : item.contentURL
        guard item.type == .video, let url = candidateURL else { return }
        if intent == .hoverIntent,
           !url.isFileURL,
           item.downloadQuality == url.absoluteString {
            return
        }
        preloadVideo(url: url, intent: intent)
    }

    func preloadVideos(urls: [URL], limit: Int, intent: PreviewIntent = .visibleCard) {
        VideoPreloader.shared.preload(urls: urls, limit: min(limit, intent.videoPreloadLimit), priority: intent.priority)
    }

    func preloadPreviewVideos(for items: [MediaItem], limit: Int, intent: PreviewIntent = .visibleCard) {
        preloadVideos(urls: items.compactMap(previewVideoURL(for:)), limit: limit, intent: intent)
    }

    func clearPreviewCache() async throws {
        try await FullResolutionPreviewCache.shared.clearCache()
    }

    private static func remoteURL(from string: String) -> URL? {
        guard let url = URL(string: string) else { return nil }
        return remoteURL(from: url)
    }

    private static func remoteURL(from url: URL) -> URL? {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return nil }
        return url
    }
}
