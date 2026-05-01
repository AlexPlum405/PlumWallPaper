// Sources/Core/ThumbnailGenerator.swift
import Foundation
import AVFoundation
import AppKit
import ImageIO
import UniformTypeIdentifiers

/// 缩略图生成器 - v2 版本
@MainActor
final class ThumbnailGenerator {
    static let shared = ThumbnailGenerator()

    private let cacheDirectory: URL

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
            try generateImageThumbnail(for: url, outputURL: outputURL)
        }

        return outputURL.path
    }

    private func generateVideoThumbnail(for url: URL, outputURL: URL) async throws {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 600, height: 338)
        let cgImage = try await generator.image(at: CMTime(seconds: 1, preferredTimescale: 600)).image
        try saveJPEG(cgImage: cgImage, to: outputURL)
    }

    private func generateImageThumbnail(for url: URL, outputURL: URL) throws {
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
        try saveJPEG(cgImage: cgImage, to: outputURL)
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
