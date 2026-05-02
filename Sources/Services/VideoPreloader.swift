// Sources/Services/VideoPreloader.swift
import Foundation
import AVFoundation

/// 视频预加载管理器
class VideoPreloader {
    static let shared = VideoPreloader()

    private var preloadedPlayers: [URL: AVPlayer] = [:]
    private var preloadTasks: [URL: Task<Void, Never>] = [:]
    private let queue = DispatchQueue(label: "com.plumwallpaper.videopreloader", qos: .utility)

    private init() {}

    /// 批量预加载视频，保留前几个最可能马上被用户看到的项目。
    func preload(urls: [URL], limit: Int = 6) {
        for url in Array(urls.prefix(limit)) {
            preload(url: url)
        }
    }

    /// 预加载视频
    func preload(url: URL) {
        queue.async { [weak self] in
            guard let self = self else { return }

            // 如果已经预加载或正在预加载，跳过
            if self.preloadedPlayers[url] != nil || self.preloadTasks[url] != nil {
                NSLog("[VideoPreloader] 视频已在预加载队列: \(url.lastPathComponent)")
                return
            }

            NSLog("[VideoPreloader] 开始预加载: \(url.lastPathComponent)")

            let task = Task {
                let asset = AVURLAsset(
                    url: url,
                    options: [
                        "AVURLAssetHTTPHeaderFieldsKey": [
                            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
                        ]
                    ]
                )

                // 预加载视频元数据和部分内容
                do {
                    // 加载视频轨道信息
                    let tracks = try await asset.loadTracks(withMediaType: .video)
                    if !tracks.isEmpty {
                        NSLog("[VideoPreloader] ✅ 预加载成功: \(url.lastPathComponent)")

                        // 创建 player 并预加载
                        let playerItem = AVPlayerItem(asset: asset)
                        playerItem.preferredForwardBufferDuration = 5
                        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true

                        let player = AVPlayer(playerItem: playerItem)
                        player.isMuted = true
                        player.automaticallyWaitsToMinimizeStalling = false

                        self.queue.async {
                            self.preloadedPlayers[url] = player
                        }

                        if await self.waitUntilReady(playerItem) {
                            await withCheckedContinuation { continuation in
                                player.preroll(atRate: 1.0) { success in
                                    if success {
                                        NSLog("[VideoPreloader] ✅ 预加载第一帧成功: \(url.lastPathComponent)")
                                    }
                                    continuation.resume()
                                }
                            }
                        } else {
                            NSLog("[VideoPreloader] ⚠️ PlayerItem 未准备好，保留已创建播放器: \(url.lastPathComponent)")
                        }

                        self.queue.async {
                            self.preloadTasks[url] = nil
                        }
                    }
                } catch {
                    NSLog("[VideoPreloader] ❌ 预加载失败: \(url.lastPathComponent), 错误: \(error)")
                    self.queue.async {
                        self.preloadTasks[url] = nil
                    }
                }
            }

            self.preloadTasks[url] = task
        }
    }

    private func waitUntilReady(_ item: AVPlayerItem, timeoutNanoseconds: UInt64 = 4_000_000_000) async -> Bool {
        let interval: UInt64 = 100_000_000
        let attempts = max(1, Int(timeoutNanoseconds / interval))

        for _ in 0..<attempts {
            if Task.isCancelled { return false }
            switch item.status {
            case .readyToPlay:
                return true
            case .failed:
                return false
            default:
                try? await Task.sleep(nanoseconds: interval)
            }
        }

        return item.status == .readyToPlay
    }

    /// 获取预加载的播放器
    func getPreloadedPlayer(url: URL) -> AVPlayer? {
        var player: AVPlayer?
        queue.sync {
            player = preloadedPlayers[url]
            preloadedPlayers[url] = nil
        }
        return player
    }

    /// 取消预加载
    func cancelPreload(url: URL) {
        queue.async { [weak self] in
            self?.preloadTasks[url]?.cancel()
            self?.preloadTasks[url] = nil
            NSLog("[VideoPreloader] 取消预加载: \(url.lastPathComponent)")
        }
    }

    /// 清理预加载的播放器
    func cleanup(url: URL) {
        queue.async { [weak self] in
            if let player = self?.preloadedPlayers[url] {
                player.pause()
                self?.preloadedPlayers[url] = nil
                NSLog("[VideoPreloader] 清理预加载播放器: \(url.lastPathComponent)")
            }
        }
    }

    /// 清理所有预加载
    func cleanupAll() {
        queue.async { [weak self] in
            guard let self = self else { return }

            for (_, player) in self.preloadedPlayers {
                player.pause()
            }
            self.preloadedPlayers.removeAll()

            for (_, task) in self.preloadTasks {
                task.cancel()
            }
            self.preloadTasks.removeAll()

            NSLog("[VideoPreloader] 清理所有预加载")
        }
    }
}
