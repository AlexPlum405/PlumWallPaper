// Sources/Services/DownloadManager.swift
import Foundation
import SwiftData

/// 下载管理器
@MainActor
final class DownloadManager: ObservableObject {
    static let shared = DownloadManager()

    @Published var activeDownloads: [String: DownloadTask] = [:]

    private let networkService = NetworkService.shared
    private let fileManager = FileManager.default

    // 下载目录
    private lazy var downloadsDirectory: URL = {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("PlumWallPaper/Downloads", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private init() {}

    // MARK: - Public Methods

    /// 下载在线壁纸
    func downloadWallpaper(
        item: WallpaperDisplayItem,
        quality: String,
        downloadURL: URL,
        context: ModelContext
    ) async throws -> Wallpaper {
        let taskId = UUID().uuidString

        // 创建下载任务
        let task = DownloadTask(
            id: taskId,
            title: item.title,
            quality: quality,
            totalSize: 0,
            downloadedSize: 0,
            progress: 0,
            status: .downloading
        )

        activeDownloads[taskId] = task

        do {
            // 生成文件名
            let filename = generateFilename(for: item, quality: quality)
            let destinationURL = downloadsDirectory.appendingPathComponent(filename)

            // 下载文件
            try await networkService.downloadFile(
                from: downloadURL,
                to: destinationURL,
                progressHandler: { [weak self] progress in
                    Task { @MainActor in
                        self?.updateTask(taskId) { task in
                            task.progress = progress
                        }
                    }
                }
            )

            // 更新任务状态
            updateTask(taskId) { task in
                task.progress = 1
                task.status = .completed
            }

            // 导入到 SwiftData
            let wallpaper = try await importToSwiftData(
                item: item,
                localURL: destinationURL,
                quality: quality,
                context: context
            )

            scheduleRemoval(for: taskId)

            return wallpaper
        } catch {
            updateTask(taskId) { task in
                task.status = .failed
                task.error = error.localizedDescription
            }
            scheduleRemoval(for: taskId, delay: 6)
            throw error
        }
    }

    /// 检查是否已下载
    func isAlreadyDownloaded(remoteId: String, context: ModelContext) -> Wallpaper? {
        let descriptor = FetchDescriptor<Wallpaper>(
            predicate: #Predicate { wallpaper in
                wallpaper.remoteId == remoteId
            }
        )

        return try? context.fetch(descriptor).first { wallpaper in
            wallpaper.source == .downloaded
                && !Self.isRemotePath(wallpaper.filePath)
                && fileManager.fileExists(atPath: wallpaper.filePath)
        }
    }

    // MARK: - Private Methods

    private func generateFilename(for item: WallpaperDisplayItem, quality: String) -> String {
        let ext: String
        switch item.type {
        case .image, .heic:
            ext = "jpg"
        case .video:
            ext = "mp4"
        }

        let sanitizedTitle = item.title
            .replacingOccurrences(of: "[^a-zA-Z0-9]", with: "_", options: .regularExpression)
            .prefix(50)

        let sanitizedQuality = quality
            .replacingOccurrences(of: "[^a-zA-Z0-9_\\-]", with: "_", options: .regularExpression)
            .prefix(30)

        return "\(sanitizedTitle)_\(sanitizedQuality).\(ext)"
    }

    private func importToSwiftData(
        item: WallpaperDisplayItem,
        localURL: URL,
        quality: String,
        context: ModelContext
    ) async throws -> Wallpaper {
        // 获取文件信息
        let attributes = try fileManager.attributesOfItem(atPath: localURL.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        let remoteId = extractRemoteId(from: item)
        let remoteSource = extractRemoteSource(from: item)
        let metadata = RemoteMetadata(
            author: extractAuthor(from: item),
            views: item.views,
            favorites: item.favorites,
            uploadDate: extractUploadDate(from: item),
            originalURL: extractOriginalURL(from: item)
        )

        let descriptor = FetchDescriptor<Wallpaper>(
            predicate: #Predicate { wallpaper in
                wallpaper.remoteId == remoteId
            }
        )

        if let existing = try context.fetch(descriptor).first {
            existing.name = item.title
            existing.filePath = localURL.path
            existing.type = item.type
            existing.resolution = item.resolution
            existing.fileSize = fileSize
            existing.thumbnailPath = item.thumbnailURL?.absoluteString
            existing.source = .downloaded
            existing.remoteId = remoteId
            existing.remoteSource = remoteSource
            existing.downloadQuality = quality
            existing.remoteMetadata = metadata
            try context.save()
            return existing
        }

        // 创建 Wallpaper 对象
        let wallpaper = Wallpaper(
            name: item.title,
            filePath: localURL.path,
            type: item.type,
            resolution: item.resolution,
            fileSize: fileSize,
            source: .downloaded,
            remoteId: remoteId,
            remoteSource: remoteSource,
            downloadQuality: quality,
            remoteMetadata: metadata
        )

        context.insert(wallpaper)
        try context.save()

        return wallpaper
    }

    private func extractRemoteId(from item: WallpaperDisplayItem) -> String {
        switch item {
        case .remote(let w): return w.id
        case .media(let m): return m.id
        case .local(let w): return w.remoteId ?? w.id.uuidString
        }
    }

    private func extractRemoteSource(from item: WallpaperDisplayItem) -> RemoteSourceType {
        switch item {
        case .remote(let w):
            if w.id.hasPrefix("pexels_") { return .pexels }
            if w.id.hasPrefix("unsplash_") { return .unsplash }
            if w.id.hasPrefix("pixabay_") { return .pixabay }
            if w.id.hasPrefix("bing_") { return .bingDaily }
            return .wallhaven
        case .media(let m):
            switch m.sourceName.lowercased() {
            case "motionbg": return .motionBG
            case "steam workshop": return .steamWorkshop
            case "pexels": return .pexels
            case "pixabay": return .pixabay
            case "desktophut": return .desktopHut
            default: return .motionBG
            }
        case .local(let w): return w.remoteSource ?? .wallhaven
        }
    }

    private func extractAuthor(from item: WallpaperDisplayItem) -> String? {
        switch item {
        case .media(let media): return media.authorName
        case .remote, .local: return nil
        }
    }

    private func extractUploadDate(from item: WallpaperDisplayItem) -> Date? {
        switch item {
        case .remote(let wallpaper): return wallpaper.uploadedAt
        case .media(let media): return media.createdAt
        case .local(let wallpaper): return wallpaper.importDate
        }
    }

    private func extractOriginalURL(from item: WallpaperDisplayItem) -> String? {
        switch item {
        case .remote(let wallpaper): return wallpaper.url
        case .media(let media): return media.pageURL.absoluteString
        case .local(let wallpaper): return wallpaper.remoteMetadata?.originalURL
        }
    }

    private static func isRemotePath(_ path: String) -> Bool {
        guard let url = URL(string: path), let scheme = url.scheme?.lowercased() else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }

    private func updateTask(_ taskId: String, mutate: (inout DownloadTask) -> Void) {
        guard var task = activeDownloads[taskId] else { return }
        mutate(&task)
        activeDownloads[taskId] = task
    }

    private func scheduleRemoval(for taskId: String, delay: TimeInterval = 3.5) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            activeDownloads.removeValue(forKey: taskId)
        }
    }
}

/// 下载任务
struct DownloadTask: Identifiable {
    let id: String
    let title: String
    let quality: String
    let createdAt: Date = Date()
    var totalSize: Int64
    var downloadedSize: Int64
    var progress: Double
    var status: DownloadStatus
    var error: String?
}

enum DownloadStatus {
    case waiting
    case downloading
    case completed
    case failed
}
