//
//  WallpaperRenderer.swift
//  PlumWallPaper
//
//  Created on 2026-04-28.
//

import Foundation
import AVFoundation
import AppKit

/// 壁纸渲染器协议
protocol WallpaperRenderer {
    /// 开始渲染
    func start()

    /// 停止渲染
    func stop()

    /// 暂停渲染
    func pause()

    /// 恢复渲染
    func resume()

    /// 应用色彩滤镜
    func applyFilter(_ preset: FilterPreset)

    /// 移除滤镜
    func removeFilter()
}

/// 视频壁纸渲染器
final class VideoRenderer: WallpaperRenderer {
    private let wallpaper: Wallpaper
    private let screen: NSScreen
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var looper: AVPlayerLooper?

    init(wallpaper: Wallpaper, screen: NSScreen) {
        self.wallpaper = wallpaper
        self.screen = screen
    }

    func start() {
        // TODO: 实现视频渲染逻辑
        // 1. 创建 AVPlayer
        // 2. 配置硬件解码
        // 3. 创建 AVPlayerLayer
        // 4. 设置循环播放
        // 5. 添加到桌面窗口
    }

    func stop() {
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
        looper = nil
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        player?.play()
    }

    func applyFilter(_ preset: FilterPreset) {
        // TODO: 使用 AVVideoComposition 应用 Core Image 滤镜
    }

    func removeFilter() {
        // TODO: 移除滤镜
    }
}

/// HEIC 动态壁纸渲染器
final class HEICRenderer: WallpaperRenderer {
    private let wallpaper: Wallpaper
    private let screen: NSScreen
    private let desktopBridge: DesktopBridge

    init(wallpaper: Wallpaper, screen: NSScreen, desktopBridge: DesktopBridge) {
        self.wallpaper = wallpaper
        self.screen = screen
        self.desktopBridge = desktopBridge
    }

    func start() {
        let url = URL(fileURLWithPath: wallpaper.filePath)
        try? desktopBridge.setDesktopImage(url, for: screen)
    }

    func stop() {
        // HEIC 由系统管理，无需手动停止
    }

    func pause() {
        // HEIC 不支持暂停
    }

    func resume() {
        // HEIC 不支持恢复
    }

    func applyFilter(_ preset: FilterPreset) {
        let url = URL(fileURLWithPath: wallpaper.filePath)
        guard let processedImage = FilterEngine.shared.applyToImage(at: url, preset: preset) else { return }
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("plum_filter_\(wallpaper.id.uuidString).png")
        if let tiff = processedImage.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: tmpURL)
            try? desktopBridge.setDesktopImage(tmpURL, for: screen)
        }
    }

    func removeFilter() {
        let url = URL(fileURLWithPath: wallpaper.filePath)
        try? desktopBridge.setDesktopImage(url, for: screen)
    }
}
