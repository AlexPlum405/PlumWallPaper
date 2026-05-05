// Sources/Views/Components/VideoPlayer.swift
import SwiftUI
import AVFoundation
import QuartzCore

/// 简单的视频播放器组件，用于 Hero 轮播
struct VideoPlayer: View {
    let url: URL
    let posterURL: URL?
    var isActive: Bool = true  // 是否激活（控制播放/暂停）

    @State private var player: AVPlayer?
    @State private var isVideoReady = false
    @State private var statusObservation: NSKeyValueObservation?
    @State private var endObserver: NSObjectProtocol?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let posterURL = posterURL {
                    AsyncImage(url: posterURL) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Color.black
                        }
                    }
                } else {
                    Color.black
                }

                if let player = player {
                    PlayerLayerHost(player: player)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .allowsHitTesting(false)
                        .opacity(isVideoReady ? 1 : 0)
                        .animation(.easeInOut(duration: 0.22), value: isVideoReady)
                        .onAppear {
                            NSLog("[VideoPlayer] PlayerLayerHost 已显示")
                        }
                }
            }
        }
        .onAppear {
            NSLog("[VideoPlayer] VideoPlayer.onAppear 被调用，URL: \(url.absoluteString)")
            setupPlayer()
        }
        .onDisappear {
            NSLog("[VideoPlayer] VideoPlayer.onDisappear 被调用")
            teardownPlayer()
        }
        .onChange(of: url) { oldURL, newURL in
            NSLog("[VideoPlayer] URL 改变: \(oldURL.lastPathComponent) -> \(newURL.lastPathComponent)")
            teardownPlayer()
            setupPlayer()
        }
        .onChange(of: isActive) { oldValue, newValue in
            NSLog("[VideoPlayer] isActive 改变: \(oldValue) -> \(newValue), URL: \(url.lastPathComponent)")
            if newValue {
                // 激活时播放
                player?.play()
                NSLog("[VideoPlayer] ▶️ 开始播放: \(url.lastPathComponent)")
            } else {
                // 非激活时暂停
                player?.pause()
                NSLog("[VideoPlayer] ⏸️ 暂停播放: \(url.lastPathComponent)")
            }
        }
    }

    private func teardownPlayer() {
        player?.pause()
        player = nil
        isVideoReady = false
        statusObservation?.invalidate()
        statusObservation = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }

    private func setupPlayer() {
        NSLog("[VideoPlayer] setupPlayer 开始，URL: \(url.absoluteString)")
        isVideoReady = false

        // 尝试使用预加载的播放器
        if let preloadedPlayer = VideoPreloader.shared.getPreloadedPlayer(url: url) {
            NSLog("[VideoPlayer] ✅ 使用预加载的播放器")
            configure(player: preloadedPlayer)
            return
        }

        // 如果没有预加载，创建新的播放器
        let playerItem = AVPlayerItem(url: url)
        playerItem.preferredForwardBufferDuration = 3
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true

        let avPlayer = AVPlayer(playerItem: playerItem)
        configure(player: avPlayer)
    }

    private func configure(player avPlayer: AVPlayer) {
        avPlayer.isMuted = false
        avPlayer.volume = 1.0  // 确保音量为最大
        avPlayer.automaticallyWaitsToMinimizeStalling = false

        self.player = avPlayer

        NSLog("[VideoPlayer] 开始播放...")

        // 根据 isActive 决定是否播放
        if isActive {
            if avPlayer.currentTime() > .zero {
                avPlayer.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
            }
            avPlayer.play()
            NSLog("[VideoPlayer] ▶️ 激活状态，开始播放")
        } else {
            NSLog("[VideoPlayer] ⏸️ 非激活状态，保持暂停")
        }

        // 循环播放
        if let currentItem = avPlayer.currentItem {
            currentItem.preferredForwardBufferDuration = max(currentItem.preferredForwardBufferDuration, 3)
            currentItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true

            statusObservation = currentItem.observe(\.status, options: [.initial, .new]) { item, _ in
                DispatchQueue.main.async {
                    switch item.status {
                    case .readyToPlay:
                        isVideoReady = true
                        if isActive {
                            if avPlayer.rate == 0 {
                                avPlayer.seek(to: avPlayer.currentTime(), toleranceBefore: .zero, toleranceAfter: .positiveInfinity)
                            }
                            avPlayer.play()
                        }
                        NSLog("[VideoPlayer] ✅ 首帧可播放: \(url.lastPathComponent)")
                    case .failed:
                        isVideoReady = false
                        if let error = item.error {
                            NSLog("[VideoPlayer] ❌ 播放错误: \(error.localizedDescription)")
                        }
                    default:
                        break
                    }
                }
            }

            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: currentItem,
                queue: .main
            ) { _ in
                NSLog("[VideoPlayer] 视频播放结束，重新开始")
                avPlayer.seek(to: .zero)
                if isActive {
                    avPlayer.play()
                }
            }
        }

        NSLog("[VideoPlayer] 播放器已设置: \(url.absoluteString)")
        NSLog("[VideoPlayer] 静音状态: \(avPlayer.isMuted), 音量: \(avPlayer.volume)")

        // 检查播放状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NSLog("[VideoPlayer] 1秒后检查 - 播放速率: \(avPlayer.rate), 状态: \(avPlayer.status.rawValue)")
            if let item = avPlayer.currentItem {
                NSLog("[VideoPlayer] PlayerItem 状态: \(item.status.rawValue)")
                if let error = item.error {
                    NSLog("[VideoPlayer] ❌ 播放错误: \(error.localizedDescription)")
                }
            }
        }
    }
}

private struct PlayerLayerHost: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> PlayerLayerContainerView {
        let view = PlayerLayerContainerView()
        view.player = player
        return view
    }

    func updateNSView(_ nsView: PlayerLayerContainerView, context: Context) {
        nsView.player = player
    }
}

private final class PlayerLayerContainerView: NSView {
    private let playerLayer = AVPlayerLayer()

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        wantsLayer = true
        let rootLayer = CALayer()
        rootLayer.backgroundColor = NSColor.black.cgColor
        rootLayer.masksToBounds = true
        layer = rootLayer

        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.needsDisplayOnBoundsChange = true
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        rootLayer.addSublayer(playerLayer)
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}

struct HeroVideoPlayer: NSViewRepresentable {
    let url: URL
    var isActive: Bool = true
    var onReadyChanged: (Bool) -> Void = { _ in }

    func makeNSView(context: Context) -> HeroVideoPlayerView {
        let view = HeroVideoPlayerView()
        view.onReadyChanged = onReadyChanged
        view.configure(url: url, isActive: isActive)
        return view
    }

    func updateNSView(_ nsView: HeroVideoPlayerView, context: Context) {
        nsView.onReadyChanged = onReadyChanged
        nsView.configure(url: url, isActive: isActive)
    }

    static func dismantleNSView(_ nsView: HeroVideoPlayerView, coordinator: ()) {
        nsView.stop()
    }
}

final class HeroVideoPlayerView: NSView {
    private var player = AVPlayer()
    private let playerLayer = AVPlayerLayer()
    private var currentURL: URL?
    private var endObserver: NSObjectProtocol?
    private var statusObservation: NSKeyValueObservation?
    private var isCurrentlyActive = true  // 添加状态跟踪
    var onReadyChanged: ((Bool) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.backgroundColor = NSColor.black.cgColor
        playerLayer.needsDisplayOnBoundsChange = true
        layer = playerLayer
    }

    func configure(url: URL, isActive: Bool) {
        isCurrentlyActive = isActive  // 更新状态

        if currentURL != url {
            currentURL = url
            notifyReady(false)
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
                self.endObserver = nil
            }
            statusObservation?.invalidate()
            statusObservation = nil

            if let preloadedPlayer = VideoPreloader.shared.getPreloadedPlayer(url: url) {
                player.pause()
                player = preloadedPlayer
                playerLayer.player = preloadedPlayer
                player.isMuted = true
                player.automaticallyWaitsToMinimizeStalling = false

                if let item = preloadedPlayer.currentItem {
                    observeReadiness(for: item, player: preloadedPlayer, url: url)
                    installLoopObserver(for: item, url: url)
                }

                if isActive {
                    player.play()
                }
                return
            }

            let asset = AVURLAsset(
                url: url,
                options: [
                    "AVURLAssetHTTPHeaderFieldsKey": [
                        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
                    ]
                ]
            )
            let playerItem = AVPlayerItem(asset: asset)
            playerItem.preferredForwardBufferDuration = 3
            playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
            player.replaceCurrentItem(with: playerItem)
            player.isMuted = true
            player.volume = 0
            player.automaticallyWaitsToMinimizeStalling = false

            observeReadiness(for: playerItem, player: player, url: url)
            installLoopObserver(for: playerItem, url: url)
        }

        if isActive {
            player.play()
        } else {
            player.pause()
        }
    }

    private func observeReadiness(for item: AVPlayerItem, player observedPlayer: AVPlayer, url: URL) {
        statusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self, weak observedPlayer] item, _ in
            DispatchQueue.main.async {
                guard let self, self.currentURL == url else { return }
                switch item.status {
                case .readyToPlay:
                    self.notifyReady(true)
                    if self.isCurrentlyActive, observedPlayer?.rate == 0 {
                        observedPlayer?.play()
                    }
                    NSLog("[HeroVideoPlayer] ✅ 首帧可播放: \(url.lastPathComponent)")
                case .failed:
                    self.notifyReady(false)
                    NSLog("[HeroVideoPlayer] ❌ 播放失败: \(item.error?.localizedDescription ?? "unknown")")
                default:
                    break
                }
            }
        }
    }

    private func installLoopObserver(for item: AVPlayerItem, url: URL) {
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self = self, self.currentURL == url else { return }
            NSLog("[HeroVideoPlayer] 视频播放结束，循环播放")
            self.player.seek(to: .zero)
            if self.isCurrentlyActive {
                self.player.play()
            }
        }
    }

    private func notifyReady(_ isReady: Bool) {
        onReadyChanged?(isReady)
    }

    func stop() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        statusObservation?.invalidate()
        statusObservation = nil
        notifyReady(false)
        player.pause()
        player.replaceCurrentItem(with: nil)
        currentURL = nil
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}
