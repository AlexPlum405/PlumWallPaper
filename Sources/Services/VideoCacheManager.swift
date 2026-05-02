// Sources/Services/VideoCacheManager.swift
import Foundation
import AVFoundation

/// 视频缓存管理器
class VideoCacheManager {
    static let shared = VideoCacheManager()

    private let cacheDirectory: URL
    private let urlCache: URLCache

    private init() {
        // 创建缓存目录
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("VideoCache", isDirectory: true)

        // 创建目录
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // 配置 URLCache - 500MB 内存缓存，2GB 磁盘缓存
        urlCache = URLCache(
            memoryCapacity: 500 * 1024 * 1024,  // 500 MB
            diskCapacity: 2 * 1024 * 1024 * 1024,  // 2 GB
            directory: cacheDirectory
        )

        URLCache.shared = urlCache

        NSLog("[VideoCacheManager] 初始化完成")
        NSLog("[VideoCacheManager] 缓存目录: \(cacheDirectory.path)")
        NSLog("[VideoCacheManager] 内存容量: 500MB, 磁盘容量: 2GB")
    }

    /// 配置 AVURLAsset 使用缓存
    func configureAsset(_ asset: AVURLAsset) {
        // AVURLAsset 会自动使用 URLCache.shared
        NSLog("[VideoCacheManager] 配置 Asset 使用缓存: \(asset.url.lastPathComponent)")
    }

    /// 获取缓存统计信息
    func getCacheStats() -> (memoryUsage: Int, diskUsage: Int) {
        let memoryUsage = urlCache.currentMemoryUsage
        let diskUsage = urlCache.currentDiskUsage

        NSLog("[VideoCacheManager] 缓存使用情况:")
        NSLog("[VideoCacheManager]   内存: \(memoryUsage / 1024 / 1024) MB / 500 MB")
        NSLog("[VideoCacheManager]   磁盘: \(diskUsage / 1024 / 1024) MB / 2048 MB")

        return (memoryUsage, diskUsage)
    }

    /// 清理缓存
    func clearCache() {
        urlCache.removeAllCachedResponses()
        NSLog("[VideoCacheManager] ✅ 清理所有缓存")
    }

    /// 清理旧缓存（超过指定天数）
    func clearOldCache(olderThanDays days: Int) {
        let fileManager = FileManager.default
        let cutoffDate = Date().addingTimeInterval(-Double(days * 24 * 60 * 60))

        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else {
            return
        }

        var deletedCount = 0
        var deletedSize: Int64 = 0

        for fileURL in files {
            guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
                  let modificationDate = attributes[.modificationDate] as? Date,
                  modificationDate < cutoffDate else {
                continue
            }

            if let fileSize = attributes[.size] as? Int64 {
                deletedSize += fileSize
            }

            try? fileManager.removeItem(at: fileURL)
            deletedCount += 1
        }

        NSLog("[VideoCacheManager] ✅ 清理 \(days) 天前的缓存")
        NSLog("[VideoCacheManager]   删除文件: \(deletedCount) 个")
        NSLog("[VideoCacheManager]   释放空间: \(deletedSize / 1024 / 1024) MB")
    }

    /// 预缓存视频
    func precacheVideo(url: URL, completion: @escaping (Bool) -> Void) {
        NSLog("[VideoCacheManager] 开始预缓存: \(url.lastPathComponent)")

        let request = URLRequest(url: url)

        // 检查是否已缓存
        if let cachedResponse = urlCache.cachedResponse(for: request) {
            NSLog("[VideoCacheManager] ✅ 视频已缓存: \(url.lastPathComponent)")
            completion(true)
            return
        }

        // 下载并缓存
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                NSLog("[VideoCacheManager] ❌ 预缓存失败: \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let data = data, let response = response else {
                NSLog("[VideoCacheManager] ❌ 预缓存失败: 无数据或响应")
                completion(false)
                return
            }

            // 存储到缓存
            let cachedResponse = CachedURLResponse(response: response, data: data)
            self.urlCache.storeCachedResponse(cachedResponse, for: request)

            NSLog("[VideoCacheManager] ✅ 预缓存成功: \(url.lastPathComponent), 大小: \(data.count / 1024 / 1024) MB")
            completion(true)
        }

        task.resume()
    }
}
