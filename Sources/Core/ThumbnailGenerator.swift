import Foundation
import AVFoundation
import AppKit
import ImageIO

/// 缩略图生成器
final class ThumbnailGenerator: @unchecked Sendable {
    static let shared = ThumbnailGenerator()

    private let cacheDirectory: URL
    private let maxConcurrentTasks = 3

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = caches.appendingPathComponent("PlumWallPaper/Thumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// 为文件生成缩略图，返回缩略图路径
    func generateThumbnail(for url: URL, type: WallpaperType) async throws -> String {
        let outputURL = cacheDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")

        switch type {
        case .video:
            try await generateVideoThumbnail(for: url, outputURL: outputURL)
        case .heic, .image:
            try await generateImageThumbnail(for: url, outputURL: outputURL)
        }

        return outputURL.path
    }

    /// 批量生成缩略图（并发优化）
    func generateThumbnails(for items: [(url: URL, type: WallpaperType)]) async -> [String?] {
        var results = [String?](repeating: nil, count: items.count)
        var startIndex = 0

        while startIndex < items.count {
            let endIndex = min(startIndex + maxConcurrentTasks, items.count)

            await withTaskGroup(of: (Int, String?).self) { group in
                for index in startIndex..<endIndex {
                    let item = items[index]
                    group.addTask { [self] in
                        let path = try? await generateThumbnail(for: item.url, type: item.type)
                        return (index, path)
                    }
                }

                for await (index, path) in group {
                    results[index] = path
                }
            }

            startIndex = endIndex
        }

        return results
    }

    private func generateVideoThumbnail(for url: URL, outputURL: URL) async throws {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 600, height: 338)

        // 优化：不等待精确时长
        generator.requestedTimeToleranceBefore = CMTime(seconds: 1, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 1, preferredTimescale: 600)

        let cgImage = try await generator.image(at: CMTime(seconds: 1, preferredTimescale: 600)).image
        try saveJPEG(cgImage: cgImage, to: outputURL)
    }

    private func generateImageThumbnail(for url: URL, outputURL: URL) async throws {
        // 移到后台线程执行
        try await Task.detached(priority: .utility) {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                throw NSError(domain: "ThumbnailGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法读取图片文件"])
            }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 600,
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                throw NSError(domain: "ThumbnailGenerator", code: 2, userInfo: [NSLocalizedDescriptionKey: "无法生成图片缩略图"])
            }
            try self.saveJPEG(cgImage: cgImage, to: outputURL)
        }.value
    }

    private func saveJPEG(cgImage: CGImage, to outputURL: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw NSError(domain: "ThumbnailGenerator", code: 3, userInfo: [NSLocalizedDescriptionKey: "无法创建输出文件"])
        }
        let properties: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.85]
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "ThumbnailGenerator", code: 4, userInfo: [NSLocalizedDescriptionKey: "无法写入缩略图"])
        }
    }

    /// 检查缓存大小，超过阈值时删除最旧的文件直到低于阈值
    func cleanCacheIfNeeded(threshold: Int64) {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]) else { return }

        var totalSize: Int64 = 0
        var fileInfos: [(url: URL, date: Date, size: Int64)] = []

        for file in files {
            guard let values = try? file.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]) else { continue }
            let size = Int64(values.fileSize ?? 0)
            let date = values.contentModificationDate ?? Date.distantPast
            totalSize += size
            fileInfos.append((url: file, date: date, size: size))
        }

        guard totalSize > threshold else { return }

        fileInfos.sort { $0.date < $1.date }

        for info in fileInfos {
            guard totalSize > threshold else { break }
            try? fm.removeItem(at: info.url)
            totalSize -= info.size
        }
    }

    /// 获取当前缓存目录大小（字节）
    func getCacheSize() -> Int64 {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        return files.reduce(Int64(0)) { total, file in
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }
}
