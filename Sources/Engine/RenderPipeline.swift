// Sources/Engine/RenderPipeline.swift
import Foundation
import AppKit
import Metal

@MainActor
final class RenderPipeline {
    static let shared = RenderPipeline()

    private let device: MTLDevice
    private var renderers: [String: ScreenRenderer] = [:]

    private init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal not supported")
        }
        self.device = device
    }

    func setupRenderers() throws {
        for screen in NSScreen.screens {
            let renderer = try ScreenRenderer(screen: screen, device: device)
            renderers[screen.localizedName] = renderer
        }
    }

    func setWallpaper(url: URL, screenId: String? = nil) async throws {
        if let screenId = screenId, let renderer = renderers[screenId] {
            try await renderer.setWallpaper(url: url)
        } else {
            for renderer in renderers.values {
                try await renderer.setWallpaper(url: url)
            }
        }
    }

    func pauseAll() {
        renderers.values.forEach { $0.pause() }
    }

    func resumeAll() {
        renderers.values.forEach { $0.resume() }
    }

    func cleanup() {
        renderers.values.forEach { $0.cleanup() }
        renderers.removeAll()
    }
}
