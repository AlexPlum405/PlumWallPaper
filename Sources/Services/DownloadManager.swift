// Sources/Services/DownloadManager.swift
import Foundation
import SwiftData

/// 下载管理器
@MainActor
final class DownloadManager: ObservableObject {
    static let shared = DownloadManager()

    @Published var activeDownloads: [String: DownloadTask] = [:]

    let maxConcurrentDownloads = 2
    private var runningDownloads: Set<String> = []
    private var waitingQueue: [String] = []
    private var waitingContinuations: [String: CheckedContinuation<Void, Never>] = [:]

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
        let remoteId = extractRemoteId(from: item)
        debugLog("开始下载: \(item.title), 当前运行数: \(runningDownloads.count), remoteId=\(remoteId)")

        let taskId = UUID().uuidString

        // 创建下载任务
        let task = DownloadTask(
            id: taskId,
            remoteId: remoteId,
            title: item.title,
            quality: quality,
            totalSize: 0,
            downloadedSize: 0,
            progress: 0,
            status: runningDownloads.count >= maxConcurrentDownloads ? .waiting : .downloading
        )

        activeDownloads[taskId] = task
        debugLog("任务已创建: \(taskId), status=\(task.status), 运行数: \(runningDownloads.count)")

        if runningDownloads.count >= maxConcurrentDownloads {
            debugLog("进入等待队列: \(taskId)")
            await waitForDownloadSlot(taskId)
        }

        guard !Task.isCancelled, activeDownloads[taskId]?.status != .cancelled else {
            cancelWaitingDownload(taskId: taskId)
            throw CancellationError()
        }

        runningDownloads.insert(taskId)
        updateTask(taskId) { task in
            task.status = .downloading
        }
        debugLog("任务开始执行: \(taskId), 运行数: \(runningDownloads.count)")

        defer {
            runningDownloads.remove(taskId)
            debugLog("任务已移除: \(taskId), 剩余运行数: \(runningDownloads.count)")
            resumeNextWaitingDownload()
        }

        do {
            // 生成文件名
            let filename = generateFilename(for: item, quality: quality)
            let destinationURL = downloadsDirectory.appendingPathComponent(filename)
            debugLog("下载到: \(destinationURL.path)")

            // 下载文件（启用重试和断点续传）
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

            debugLog("下载完成，开始导入到 SwiftData")

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

            debugLog("导入成功: \(wallpaper.name), source=\(wallpaper.source)")

            scheduleRemoval(for: taskId)

            NotificationCenter.default.post(name: .plumDownloadCompleted, object: wallpaper.remoteId)

            return wallpaper
        } catch {
            let message = userFacingDownloadError(error)
            debugLog("下载失败: \(error.localizedDescription)")
            updateTask(taskId) { task in
                task.status = .failed
                task.error = message
            }
            scheduleRemoval(for: taskId, delay: 6)
            throw NSError(
                domain: "DownloadManager",
                code: (error as NSError).code,
                userInfo: [
                    NSLocalizedDescriptionKey: message,
                    NSUnderlyingErrorKey: error
                ]
            )
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

    func activeTask(remoteId: String?) -> DownloadTask? {
        guard let remoteId else { return nil }
        return activeDownloads.values.first { task in
            task.remoteId == remoteId && (task.status == .waiting || task.status == .downloading)
        }
    }

    func activeTask(taskId: String) -> DownloadTask? {
        activeDownloads[taskId]
    }

    func queuePosition(taskId: String) -> Int? {
        guard let index = waitingQueue.firstIndex(of: taskId) else { return nil }
        return index + 1
    }

    func dismissDownload(taskId: String) {
        waitingQueue.removeAll { $0 == taskId }
        waitingContinuations.removeValue(forKey: taskId)?.resume()
        activeDownloads.removeValue(forKey: taskId)
    }

    func cancelWaitingDownload(taskId: String) {
        waitingQueue.removeAll { $0 == taskId }
        if let continuation = waitingContinuations.removeValue(forKey: taskId) {
            updateTask(taskId) { task in
                task.status = .cancelled
                task.error = "已取消"
            }
            continuation.resume()
            scheduleRemoval(for: taskId, delay: 1.2)
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
            // 生成本地缩略图
            if let localThumbnail = try? await ThumbnailGenerator.shared.generateThumbnail(for: localURL, type: item.type) {
                existing.thumbnailPath = localThumbnail
            } else {
                existing.thumbnailPath = item.thumbnailPathString
            }
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

        // 生成本地缩略图
        if let localThumbnail = try? await ThumbnailGenerator.shared.generateThumbnail(for: localURL, type: item.type) {
            wallpaper.thumbnailPath = localThumbnail
        } else {
            wallpaper.thumbnailPath = item.thumbnailPathString
        }

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
        guard var task = activeDownloads[taskId] else {
            debugLog("updateTask 失败: 任务不存在 \(taskId)")
            return
        }
        let oldStatus = task.status
        mutate(&task)
        activeDownloads[taskId] = task
        if task.status != oldStatus {
            debugLog("任务状态变化: \(taskId), \(oldStatus) -> \(task.status)")
        }
    }

    private func scheduleRemoval(for taskId: String, delay: TimeInterval = 3.5) {
        debugLog("scheduleRemoval: \(taskId), delay: \(delay)s")
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            debugLog("移除任务: \(taskId)")
            activeDownloads.removeValue(forKey: taskId)
        }
    }

    private func waitForDownloadSlot(_ taskId: String) async {
        guard runningDownloads.count >= maxConcurrentDownloads else { return }
        waitingQueue.append(taskId)
        await withCheckedContinuation { continuation in
            waitingContinuations[taskId] = continuation
        }
    }

    private func resumeNextWaitingDownload() {
        guard runningDownloads.count < maxConcurrentDownloads else { return }

        while !waitingQueue.isEmpty {
            let nextTaskId = waitingQueue.removeFirst()
            guard let continuation = waitingContinuations.removeValue(forKey: nextTaskId) else { continue }
            guard activeDownloads[nextTaskId]?.status == .waiting else {
                continuation.resume()
                continue
            }
            debugLog("唤醒等待任务: \(nextTaskId)")
            continuation.resume()
            break
        }
    }

    private func userFacingDownloadError(_ error: Error) -> String {
        if error is CancellationError {
            return "下载已取消"
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorTimedOut:
                return "下载超时，请检查网络后重试"
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return "网络连接中断，下载未完成"
            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost, NSURLErrorDNSLookupFailed:
                return "无法连接到资源服务器"
            case NSURLErrorCancelled:
                return "下载已取消"
            default:
                break
            }
        }

        let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return message.isEmpty ? "下载失败，请稍后重试" : message
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        NSLog("[DownloadManager] \(message)")
        #endif
    }
}

/// 下载任务
struct DownloadTask: Identifiable {
    let id: String
    let remoteId: String?
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
    case cancelled
}

enum DownloadError: LocalizedError {
    case tooManyDownloads
    case alreadyInProgress

    var errorDescription: String? {
        switch self {
        case .tooManyDownloads:
            return "同时下载数量已达上限，请等待当前下载完成"
        case .alreadyInProgress:
            return "已在下载队列中，请等待当前任务完成"
        }
    }
}
