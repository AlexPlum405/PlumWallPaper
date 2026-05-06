// Sources/Engine/ScreenRenderer.swift
import Foundation
import AppKit
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftData

@MainActor
final class ScreenRenderer {
    let screenId: String
    let desktopWindow: DesktopWindow

    private var player: AVPlayer { desktopWindow.player }
    private let screenSize: CGSize

    /// 当前壁纸 ID (用于 RestoreManager / SlideshowScheduler)
    private(set) var currentWallpaperId: UUID?
    /// 静音状态
    private(set) var isMuted: Bool = false

    init(screen: NSScreen, screenId: String) {
        self.screenId = screenId
        self.desktopWindow = DesktopWindow(screen: screen)
        self.screenSize = screen.frame.size
    }

    func setWallpaper(url: URL, wallpaperId: UUID? = nil, effects: WallpaperRenderEffects? = nil) async throws {
        NSLog("[ScreenRenderer] setWallpaper: \(url.lastPathComponent)")

        self.currentWallpaperId = wallpaperId

        desktopWindow.displayVideo()
        desktopWindow.configureEnvironment(effects: effects)

        let playerItem = AVPlayerItem(url: url)
        if let composition = makeEnhancedVideoComposition(for: url, effects: effects) {
            playerItem.videoComposition = composition
        }
        player.replaceCurrentItem(with: playerItem)

        // 循环播放
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        player.isMuted = false
        player.volume = 1.0
        isMuted = false

        // 显示窗口
        desktopWindow.alphaValue = 1.0
        desktopWindow.show()

        // 播放
        player.play()
        NSLog("[ScreenRenderer] ✅ player.play() rate=\(player.rate)")

        let settings = currentSettings()
        desktopWindow.updateDebugInfo(
            superResolution: false,
            videoEnhancement: settings?.videoEnhancementEnabled ?? false,
            wallpaperType: "视频"
        )
    }

    func setImageWallpaper(url: URL, wallpaperId: UUID? = nil, effects: WallpaperRenderEffects? = nil) async throws {
        NSLog("[ScreenRenderer] setImageWallpaper: \(url.lastPathComponent)")

        self.currentWallpaperId = wallpaperId
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)

        let displayURL = enhancedImageURLIfNeeded(for: url, effects: effects) ?? url
        try desktopWindow.displayImage(url: displayURL)
        desktopWindow.configureEnvironment(effects: effects)

        desktopWindow.alphaValue = 1.0
        desktopWindow.show()

        let settings = currentSettings()
        desktopWindow.updateDebugInfo(
            superResolution: settings?.superResolutionEnabled ?? false,
            videoEnhancement: false,
            wallpaperType: "静态图片"
        )
    }

    func updateEnvironment(effects: WallpaperRenderEffects?) {
        desktopWindow.configureEnvironment(effects: effects)
    }

    func configurePanoramaLayout(canvasFrame: CGRect, screenFrame: CGRect) {
        desktopWindow.configurePanoramaLayout(canvasFrame: canvasFrame, screenFrame: screenFrame)
    }

    @objc private func playerDidFinishPlaying() {
        player.seek(to: .zero)
        player.play()
    }

    private func makeEnhancedVideoComposition(for url: URL, effects: WallpaperRenderEffects?) -> AVVideoComposition? {
        let settings = currentSettings()
        let hasVideoEnhancement = settings?.videoEnhancementEnabled ?? false
        let hasEffects = effects?.hasVisualAdjustments ?? false
        guard hasVideoEnhancement || hasEffects else { return nil }

        let asset = AVURLAsset(url: url)
        return AVVideoComposition(asset: asset) { request in
            var image = request.sourceImage
            if let effects {
                image = WallpaperRenderEffectRenderer.apply(effects, to: image)
            }
            if hasVideoEnhancement {
                let controls = CIFilter.colorControls()
                controls.inputImage = image
                controls.contrast = 1.12
                controls.saturation = 1.08
                image = controls.outputImage ?? image

                let sharpen = CIFilter.sharpenLuminance()
                sharpen.inputImage = image
                sharpen.sharpness = 0.5
                image = sharpen.outputImage ?? image
            }
            request.finish(with: image, context: nil)
        }
    }

    private func enhancedImageURLIfNeeded(for url: URL, effects: WallpaperRenderEffects?) -> URL? {
        guard let image = NSImage(contentsOf: url),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return effects.flatMap { try? WallpaperRenderEffectRenderer.renderImage(sourceURL: url, effects: $0) }
        }

        let settings = currentSettings()
        let shouldUpscale = settings?.superResolutionEnabled ?? false
        let sharpen = settings?.superResolutionSharpen ?? true
        let scale = settings?.superResolutionScale ?? 2
        let needsUpscaling = CGFloat(cgImage.width) < screenSize.width || CGFloat(cgImage.height) < screenSize.height

        var outputCGImage = cgImage
        if shouldUpscale,
           needsUpscaling,
           let factor = SuperResolutionService.ScaleFactor(rawValue: min(max(scale, 2), 4)),
           let upscaled = SuperResolutionService.shared?.upscaleImage(cgImage, scale: factor, sharpen: sharpen) {
            outputCGImage = upscaled
        }

        var outputImage = CIImage(cgImage: outputCGImage)
        if let effects {
            outputImage = WallpaperRenderEffectRenderer.apply(effects, to: outputImage)
        }

        let context = CIContext(options: [.cacheIntermediates: false])
        guard let rendered = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        let bitmap = NSBitmapImageRep(cgImage: rendered)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("PlumEnhanced-\(UUID().uuidString).png")
        try? data.write(to: outputURL)
        return outputURL
    }

    private func currentSettings() -> Settings? {
        let context = PlumWallPaperApp.sharedModelContainer.mainContext
        let store = PreferencesStore(modelContext: context)
        return try? store.fetchSettings()
    }

    func pause() { player.pause() }
    func resume() { player.play() }

    func setMuted(_ muted: Bool) {
        isMuted = muted
        player.isMuted = muted
    }

    func setOpacity(_ alpha: CGFloat) {
        desktopWindow.alphaValue = alpha
    }

    func cleanup() {
        NotificationCenter.default.removeObserver(self)
        desktopWindow.configureEnvironment(effects: nil)
        player.pause()
        player.replaceCurrentItem(with: nil)
        desktopWindow.hide()
        desktopWindow.alphaValue = 0
    }
}
