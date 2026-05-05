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
        Task(priority: .background) {
            let descriptor = FetchDescriptor<Wallpaper>(
                predicate: #Predicate { $0.frameRate == nil }
            )

            let candidates: [FrameRateBackfillCandidate]
            do {
                candidates = try modelContext.fetch(descriptor)
                    .filter { $0.type == .video }
                    .map { FrameRateBackfillCandidate(id: $0.id, filePath: $0.filePath) }
            } catch {
                return
            }

            guard !candidates.isEmpty else { return }

            print("[FrameRateBackfiller] 发现 \(candidates.count) 个视频壁纸缺少帧率数据，开始后台扫描...")

            var updatedCount = 0
            for candidate in candidates {
                guard let frameRate = await self.detectFrameRate(filePath: candidate.filePath) else {
                    continue
                }

                let wallpaperId = candidate.id
                let updateDescriptor = FetchDescriptor<Wallpaper>(
                    predicate: #Predicate<Wallpaper> { $0.id == wallpaperId }
                )
                if let wallpaper = try? modelContext.fetch(updateDescriptor).first {
                    wallpaper.frameRate = Double(frameRate)
                    updatedCount += 1
                }
            }

            try? modelContext.save()
            print("[FrameRateBackfiller] 帧率补全完成，已更新 \(updatedCount) 个壁纸")
        }
    }

    private nonisolated func detectFrameRate(filePath: String) async -> Int? {
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

private struct FrameRateBackfillCandidate: Sendable {
    let id: UUID
    let filePath: String
}
