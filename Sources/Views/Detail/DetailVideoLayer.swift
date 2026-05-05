import SwiftUI
import AppKit
import AVFoundation

struct DetailVideoLayerContainer: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> DetailVideoLayerView {
        let view = DetailVideoLayerView()
        view.configure(url: url)
        return view
    }

    func updateNSView(_ nsView: DetailVideoLayerView, context: Context) {
        nsView.configure(url: url)
    }

    static func dismantleNSView(_ nsView: DetailVideoLayerView, coordinator: ()) {
        nsView.stop()
    }
}

final class DetailVideoLayerView: NSView {
    private let playerLayer = AVPlayerLayer()
    private var player: AVPlayer?
    private var currentURL: URL?
    private var endObserver: NSObjectProtocol?

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(url: URL) {
        guard currentURL != url else { return }
        currentURL = url

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        player?.pause()

        if let preloadedPlayer = VideoPreloader.shared.getPreloadedPlayer(url: url) {
            configurePreloadedPlayer(preloadedPlayer, url: url)
        } else {
            configureNewPlayer(url: url)
        }
    }

    func stop() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        player?.pause()
        playerLayer.player = nil
        player = nil
        currentURL = nil
        endObserver = nil
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }

    private func setup() {
        wantsLayer = true
        let rootLayer = CALayer()
        rootLayer.backgroundColor = NSColor.black.cgColor
        rootLayer.masksToBounds = true
        layer = rootLayer
        playerLayer.videoGravity = .resizeAspectFill
        rootLayer.addSublayer(playerLayer)
    }

    private func configurePreloadedPlayer(_ preloadedPlayer: AVPlayer, url: URL) {
        NSLog("[DetailVideoLayerView] 使用预加载播放器: \(url.lastPathComponent)")
        player = preloadedPlayer
        playerLayer.player = preloadedPlayer
        preloadedPlayer.isMuted = false
        preloadedPlayer.volume = 1.0
        preloadedPlayer.play()

        if let item = preloadedPlayer.currentItem {
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { _ in
                preloadedPlayer.seek(to: .zero)
                preloadedPlayer.play()
            }
        }
    }

    private func configureNewPlayer(url: URL) {
        NSLog("[DetailVideoLayerView] 创建新播放器: \(url.lastPathComponent)")
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = false
        player.volume = 1.0
        self.player = player
        playerLayer.player = player

        Task { @MainActor in
            await self.waitUntilReadyAndPlay(player: player, item: item)
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
    }

    private func waitUntilReadyAndPlay(player: AVPlayer, item: AVPlayerItem) async {
        let maxAttempts = 50
        for _ in 0..<maxAttempts {
            if item.status == .readyToPlay {
                player.play()
                NSLog("[DetailVideoLayerView] ✅ 播放器就绪，开始播放")
                return
            }
            if item.status == .failed {
                NSLog("[DetailVideoLayerView] ❌ 播放器加载失败: \(item.error?.localizedDescription ?? "unknown")")
                return
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }

        NSLog("[DetailVideoLayerView] ⚠️ 播放器超时，强制播放")
        player.play()
    }
}
