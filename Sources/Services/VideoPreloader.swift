// Sources/Services/VideoPreloader.swift
import Foundation
import AVFoundation
import AppKit

/// 视频预加载管理器
final class VideoPreloader: @unchecked Sendable {
    static let shared = VideoPreloader()

    private var preloadedPlayers: [URL: AVPlayer] = [:]
    private var preloadTasks: [URL: Task<Void, Never>] = [:]
    private var lastAccessDates: [URL: Date] = [:]
    private var preloadPriorities: [URL: Int] = [:]
    private let queue = DispatchQueue(label: "com.plumwallpaper.videopreloader", qos: .utility)

    private init() {}

    /// 根据内存压力动态调整预加载数量
    private func adjustPreloadLimit() -> Int {
        let physicalMemoryGB = ProcessInfo.processInfo.physicalMemory / 1_073_741_824
        if physicalMemoryGB <= 8 { return 4 }
        if physicalMemoryGB <= 16 { return 6 }
        if physicalMemoryGB <= 32 { return 8 }
        return 10
    }

    /// 批量预加载视频，保留前几个最可能马上被用户看到的项目。
    func preload(urls: [URL], limit: Int = 6) {
        preload(urls: urls, limit: limit, priority: 2)
    }

    func preload(urls: [URL], limit: Int = 6, priority: Int) {
        let actualLimit = min(limit, adjustPreloadLimit())
        for url in Array(urls.prefix(actualLimit)) {
            preload(url: url, priority: priority)
        }
    }

    /// 预加载视频
    func preload(url: URL) {
        preload(url: url, priority: 2)
    }

    func preload(url: URL, priority: Int) {
        queue.async { [weak self] in
            guard let self = self else { return }

            // 如果已经预加载或正在预加载，跳过
            if self.preloadedPlayers[url] != nil || self.preloadTasks[url] != nil {
                self.lastAccessDates[url] = Date()
                self.preloadPriorities[url] = max(self.preloadPriorities[url] ?? priority, priority)
                self.debugLog("视频已在预加载队列: \(url.lastPathComponent)")
                return
            }

            let preloadLimit = self.adjustPreloadLimit()
            if self.preloadedPlayers.count + self.preloadTasks.count >= preloadLimit {
                if priority <= 1 {
                    self.debugLog("预算已满，跳过低优先级预加载: \(url.lastPathComponent)")
                    return
                }
                self.cleanupOldestPlayersIfNeeded(maxCount: preloadLimit - 1)
                guard self.preloadedPlayers.count + self.preloadTasks.count < preloadLimit else {
                    self.debugLog("预算仍满，跳过预加载: \(url.lastPathComponent)")
                    return
                }
            }

            self.preloadPriorities[url] = priority
            self.debugLog("开始预加载: \(url.lastPathComponent)")

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
                        self.debugLog("预加载成功: \(url.lastPathComponent)")

                        // 创建 player 并预加载
                        let playerItem = AVPlayerItem(asset: asset)
                        playerItem.preferredForwardBufferDuration = 5
                        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true

                        let player = AVPlayer(playerItem: playerItem)
                        player.isMuted = true
                        player.automaticallyWaitsToMinimizeStalling = false

                        self.queue.async {
                            self.preloadedPlayers[url] = player
                            self.lastAccessDates[url] = Date()
                            self.preloadPriorities[url] = priority
                            self.cleanupOldestPlayersIfNeeded(maxCount: self.adjustPreloadLimit())
                        }

                        if await self.waitUntilReady(playerItem) {
                            await withCheckedContinuation { continuation in
                                player.preroll(atRate: 1.0) { success in
                                    if success {
                                        self.debugLog("预加载第一帧成功: \(url.lastPathComponent)")
                                    }
                                    continuation.resume()
                                }
                            }
                        } else {
                            self.debugLog("PlayerItem 未准备好，保留已创建播放器: \(url.lastPathComponent)")
                        }

                        self.queue.async {
                            self.preloadTasks[url] = nil
                        }
                    }
                } catch {
                    self.debugLog("预加载失败: \(url.lastPathComponent), 错误: \(error)")
                    self.queue.async {
                        self.preloadTasks[url] = nil
                        self.preloadPriorities[url] = nil
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
            lastAccessDates[url] = nil
            preloadPriorities[url] = nil
        }
        return player
    }

    /// 检查是否已预加载
    func isPreloaded(url: URL) -> Bool {
        var result = false
        queue.sync {
            result = preloadedPlayers[url] != nil
            if result {
                lastAccessDates[url] = Date()
            }
        }
        return result
    }

    /// 取消预加载
    func cancelPreload(url: URL) {
        queue.async { [weak self] in
            self?.preloadTasks[url]?.cancel()
            self?.preloadTasks[url] = nil
            self?.preloadPriorities[url] = nil
            self?.debugLog("取消预加载: \(url.lastPathComponent)")
        }
    }

    /// 清理预加载的播放器
    func cleanup(url: URL) {
        queue.async { [weak self] in
            if let player = self?.preloadedPlayers[url] {
                player.pause()
                self?.preloadedPlayers[url] = nil
                self?.lastAccessDates[url] = nil
                self?.preloadPriorities[url] = nil
                self?.debugLog("清理预加载播放器: \(url.lastPathComponent)")
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
            self.lastAccessDates.removeAll()
            self.preloadPriorities.removeAll()

            for (_, task) in self.preloadTasks {
                task.cancel()
            }
            self.preloadTasks.removeAll()

            self.debugLog("清理所有预加载")
        }
    }

    private func cleanupOldestPlayersIfNeeded(maxCount: Int) {
        guard maxCount >= 0, preloadedPlayers.count > maxCount else { return }

        let overflow = preloadedPlayers.count - maxCount
        let urlsToRemove = preloadedPlayers.keys
            .sorted {
                let lhsPriority = preloadPriorities[$0] ?? 0
                let rhsPriority = preloadPriorities[$1] ?? 0
                if lhsPriority != rhsPriority { return lhsPriority < rhsPriority }
                return (lastAccessDates[$0] ?? .distantPast) < (lastAccessDates[$1] ?? .distantPast)
            }
            .prefix(overflow)

        for url in urlsToRemove {
            preloadedPlayers[url]?.pause()
            preloadedPlayers[url] = nil
            lastAccessDates[url] = nil
            preloadPriorities[url] = nil
            debugLog("LRU 清理预加载播放器: \(url.lastPathComponent)")
        }
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        NSLog("[VideoPreloader] \(message)")
        #endif
    }
}
