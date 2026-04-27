import Foundation
import AVFoundation
import AppKit
import ImageIO

/// 缩略图生成器
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
        case .heic:
            try generateHEICThumbnail(for: url, outputURL: outputURL)
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

    private func generateHEICThumbnail(for url: URL, outputURL: URL) throws {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw NSError(domain: "ThumbnailGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法读取 HEIC 文件"])
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 600,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw NSError(domain: "ThumbnailGenerator", code: 2, userInfo: [NSLocalizedDescriptionKey: "无法生成 HEIC 缩略图"])
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
}
