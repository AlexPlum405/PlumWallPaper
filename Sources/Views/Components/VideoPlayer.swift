// Sources/Views/Components/VideoPlayer.swift
import SwiftUI
import AVKit

/// 简单的视频播放器组件，用于 Hero 轮播
struct VideoPlayer: View {
    let url: URL
    let posterURL: URL?
    var isActive: Bool = true  // 是否激活（控制播放/暂停）

    @State private var player: AVPlayer?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let player = player {
                    VideoPlayerView(player: player)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .onAppear {
                            NSLog("[VideoPlayer] VideoPlayerView 已显示")
                        }
                } else {
                    // 加载中显示海报
                    if let posterURL = posterURL {
                        AsyncImage(url: posterURL) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                Color.black
                            }
                        }
                        .onAppear {
                            NSLog("[VideoPlayer] 显示海报图片: \(posterURL.absoluteString)")
                        }
                    } else {
                        Color.black
                            .onAppear {
                                NSLog("[VideoPlayer] 显示黑色占位符")
                            }
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
            player?.pause()
            player = nil
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

    private func setupPlayer() {
        NSLog("[VideoPlayer] setupPlayer 开始，URL: \(url.absoluteString)")

        // 尝试使用预加载的播放器
        if let preloadedPlayer = VideoPreloader.shared.getPreloadedPlayer(url: url) {
            NSLog("[VideoPlayer] ✅ 使用预加载的播放器")
            self.player = preloadedPlayer
            preloadedPlayer.isMuted = false
            preloadedPlayer.volume = 1.0
            preloadedPlayer.play()

            // 循环播放
            if let currentItem = preloadedPlayer.currentItem {
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: currentItem,
                    queue: .main
                ) { _ in
                    NSLog("[VideoPlayer] 视频播放结束，重新开始")
                    preloadedPlayer.seek(to: .zero)
                    preloadedPlayer.play()
                }
            }

            NSLog("[VideoPlayer] 播放器已设置: \(url.absoluteString)")
            NSLog("[VideoPlayer] 静音状态: \(preloadedPlayer.isMuted), 音量: \(preloadedPlayer.volume)")
            return
        }

        // 如果没有预加载，创建新的播放器
        let playerItem = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: playerItem)
        avPlayer.isMuted = false
        avPlayer.volume = 1.0  // 确保音量为最大

        NSLog("[VideoPlayer] 开始播放...")

        // 根据 isActive 决定是否播放
        if isActive {
            avPlayer.play()
            NSLog("[VideoPlayer] ▶️ 激活状态，开始播放")
        } else {
            NSLog("[VideoPlayer] ⏸️ 非激活状态，保持暂停")
        }

        // 循环播放
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            NSLog("[VideoPlayer] 视频播放结束，重新开始")
            avPlayer.seek(to: .zero)
            avPlayer.play()
        }

        self.player = avPlayer

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

/// AVPlayerLayer 的 SwiftUI 包装
struct VideoPlayerView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = view.bounds
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

        view.layer?.addSublayer(playerLayer)

        NSLog("[VideoPlayerView] 创建视图，player: \(player)")
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // 更新 player layer 的 player
        if let sublayers = nsView.layer?.sublayers {
            for sublayer in sublayers {
                if let playerLayer = sublayer as? AVPlayerLayer {
                    playerLayer.player = player
                    playerLayer.frame = nsView.bounds
                    NSLog("[VideoPlayerView] 更新播放器")
                }
            }
        }
    }
}
