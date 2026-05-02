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
                        self?.activeDownloads[taskId]?.progress = progress
                    }
                }
            )

            // 更新任务状态
            activeDownloads[taskId]?.status = .completed

            // 导入到 SwiftData
            let wallpaper = try await importToSwiftData(
                item: item,
                localURL: destinationURL,
                quality: quality,
                context: context
            )

            // 移除任务
            activeDownloads.removeValue(forKey: taskId)

            return wallpaper
        } catch {
            activeDownloads[taskId]?.status = .failed
            activeDownloads[taskId]?.error = error.localizedDescription
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

        return try? context.fetch(descriptor).first
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

        return "\(sanitizedTitle)_\(quality).\(ext)"
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

        // 创建 Wallpaper 对象
        let wallpaper = Wallpaper(
            name: item.title,
            filePath: localURL.path,
            type: item.type,
            resolution: item.resolution,
            fileSize: fileSize,
            source: .downloaded,
            remoteId: extractRemoteId(from: item),
            remoteSource: extractRemoteSource(from: item),
            downloadQuality: quality,
            remoteMetadata: RemoteMetadata(
                author: nil,
                views: item.views,
                favorites: item.favorites,
                uploadDate: Date(),
                originalURL: nil
            )
        )

        context.insert(wallpaper)
        try context.save()

        return wallpaper
    }

    private func extractRemoteId(from item: WallpaperDisplayItem) -> String {
        switch item {
        case .remote(let w): return w.id
        case .media(let m): return m.id
        case .local(let w): return w.id.uuidString
        }
    }

    private func extractRemoteSource(from item: WallpaperDisplayItem) -> RemoteSourceType {
        switch item {
        case .remote: return .wallhaven
        case .media(let m):
            return m.sourceName == "MotionBG" ? .motionBG : .steamWorkshop
        case .local: return .wallhaven
        }
    }
}

/// 下载任务
struct DownloadTask: Identifiable {
    let id: String
    let title: String
    let quality: String
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
