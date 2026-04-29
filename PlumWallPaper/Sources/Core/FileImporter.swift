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
        let fileHash = try await quickHash(url: url)
        let type = wallpaperType(for: url)
        let thumbnailPath = try await ThumbnailGenerator.shared.generateThumbnail(for: url, type: type)
        let resolution = try await detectResolution(for: url, type: type)
        let duration = try await detectDuration(for: url, type: type)
        let hasAudio = try await detectAudio(for: url, type: type)
        let frameRate = try await detectFrameRate(for: url, type: type)

        return Wallpaper(
            name: url.deletingPathExtension().lastPathComponent,
            filePath: url.path,
            type: type,
            resolution: resolution,
            fileSize: fileSize,
            duration: duration,
            thumbnailPath: thumbnailPath,
            fileHash: fileHash,
            hasAudio: hasAudio,
            frameRate: frameRate
        )
    }

    private func wallpaperType(for url: URL) -> WallpaperType {
        let ext = url.pathExtension.lowercased()
        if ext == "heic" || ext == "heif" {
            return .heic
        }
        if ext == "jpg" || ext == "jpeg" || ext == "png" || ext == "gif" || ext == "bmp" || ext == "tiff" || ext == "tif" {
            return .image
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
        case .heic, .image:
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

    private func detectFrameRate(for url: URL, type: WallpaperType) async throws -> Int? {
        guard type == .video else { return nil }
        let asset = AVAsset(url: url)
        guard let track = try await asset.loadTracks(withMediaType: .video).first else { return nil }
        let rate = try await track.load(.nominalFrameRate)
        return Int(rate.rounded())
    }

    private func detectAudio(for url: URL, type: WallpaperType) async throws -> Bool {
        guard type == .video else { return false }
        let asset = AVAsset(url: url)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard let track = audioTracks.first else { return false }

        guard let reader = try? AVAssetReader(asset: asset) else { return false }
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMBitDepthKey: 32,
            AVNumberOfChannelsKey: 1
        ]
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        reader.add(output)
        reader.startReading()

        let silenceThreshold: Float = 0.001
        var samplesChecked = 0
        let maxSamples = 48000 * 3

        while reader.status == .reading, samplesChecked < maxSamples {
            guard let buffer = output.copyNextSampleBuffer(),
                  let blockBuffer = CMSampleBufferGetDataBuffer(buffer) else { break }
            var length = 0
            var dataPointer: UnsafeMutablePointer<Int8>?
            CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
            guard let ptr = dataPointer else { continue }
            let floatCount = length / MemoryLayout<Float>.size
            let floatPtr = ptr.withMemoryRebound(to: Float.self, capacity: floatCount) { $0 }
            for i in 0..<floatCount {
                if abs(floatPtr[i]) > silenceThreshold {
                    reader.cancelReading()
                    return true
                }
            }
            samplesChecked += floatCount
        }
        reader.cancelReading()
        return false
    }

    func quickHash(url: URL) async throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: 1024 * 1024) ?? Data()
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
