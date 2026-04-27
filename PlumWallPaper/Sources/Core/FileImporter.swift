import Foundation
import AVFoundation
import AppKit
import CryptoKit

/// 文件导入器
final class FileImporter {
    static let shared = FileImporter()

    private init() {}

    /// 批量导入文件
    func importFiles(urls: [URL]) async throws -> [Wallpaper] {
        var imported: [Wallpaper] = []
        for url in urls {
            let wallpaper = try await importFile(url: url)
            imported.append(wallpaper)
        }
        return imported
    }

    /// 导入单个文件
    func importFile(url: URL) async throws -> Wallpaper {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = (attributes[.size] as? NSNumber)?.int64Value ?? 0
        let fileHash = try await calculateFileHash(url: url)
        let type = wallpaperType(for: url)
        let thumbnailPath = try await ThumbnailGenerator.shared.generateThumbnail(for: url, type: type)
        let resolution = try await detectResolution(for: url, type: type)
        let duration = try await detectDuration(for: url, type: type)

        return Wallpaper(
            name: url.deletingPathExtension().lastPathComponent,
            filePath: url.path,
            type: type,
            resolution: resolution,
            fileSize: fileSize,
            duration: duration,
            thumbnailPath: thumbnailPath,
            fileHash: fileHash
        )
    }

    private func wallpaperType(for url: URL) -> WallpaperType {
        let ext = url.pathExtension.lowercased()
        if ext == "heic" || ext == "heif" {
            return .heic
        }
        return .video
    }

    private func detectResolution(for url: URL, type: WallpaperType) async throws -> String {
        switch type {
        case .video:
            let asset = AVAsset(url: url)
            guard let track = try await asset.loadTracks(withMediaType: .video).first else {
                return "Unknown"
            }
            let size = try await track.load(.naturalSize)
            return "\(Int(size.width))×\(Int(size.height))"
        case .heic:
            guard let image = NSImage(contentsOf: url) else { return "Unknown" }
            return "\(Int(image.size.width))×\(Int(image.size.height))"
        }
    }

    private func detectDuration(for url: URL, type: WallpaperType) async throws -> TimeInterval? {
        guard type == .video else { return nil }
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }

    private func calculateFileHash(url: URL) async throws -> String {
        let data = try Data(contentsOf: url)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
