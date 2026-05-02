import Foundation
import AVFoundation
import SwiftData

/// 后台补全壁纸帧率元数据
@MainActor
final class FrameRateBackfiller {
    static let shared = FrameRateBackfiller()

    private init() {}

    /// 启动时静默扫描并补全缺失的帧率数据
    func backfillMissingFrameRates(modelContext: ModelContext) {
        Task.detached(priority: .background) {
            let descriptor = FetchDescriptor<Wallpaper>(
                predicate: #Predicate { $0.frameRate == nil }
            )

            let wallpapers: [Wallpaper]
            do {
                let all = try await MainActor.run { try modelContext.fetch(descriptor) }
                wallpapers = all.filter { $0.type == .video }
            } catch {
                return
            }

            guard !wallpapers.isEmpty else { return }

            print("[FrameRateBackfiller] 发现 \(wallpapers.count) 个视频壁纸缺少帧率数据，开始后台扫描...")

            for wallpaper in wallpapers {
                guard let frameRate = await self.detectFrameRate(filePath: wallpaper.filePath) else {
                    continue
                }

                await MainActor.run {
                    wallpaper.frameRate = Double(frameRate)
                }
            }

            await MainActor.run {
                try? modelContext.save()
                print("[FrameRateBackfiller] 帧率补全完成，已更新 \(wallpapers.count) 个壁纸")
            }
        }
    }

    private func detectFrameRate(filePath: String) async -> Int? {
        let url = URL(fileURLWithPath: filePath)
        guard FileManager.default.fileExists(atPath: filePath) else { return nil }

        let asset = AVAsset(url: url)
        guard let track = try? await asset.loadTracks(withMediaType: .video).first else {
            return nil
        }

        let rate = try? await track.load(.nominalFrameRate)
        return rate.map { Int($0.rounded()) }
    }
}
