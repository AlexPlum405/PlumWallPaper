import Foundation
import AppKit
import SwiftData

@MainActor
final class WallpaperTopologyCoordinator {
    static let shared = WallpaperTopologyCoordinator()

    private init() {}

    func apply(
        wallpaper: Wallpaper,
        renderedURL: URL? = nil,
        effects: WallpaperRenderEffects? = nil,
        settings: Settings,
        displayManager: DisplayManager = .shared,
        targetScreenId: String? = nil
    ) async throws -> String {
        NSLog("[WallpaperTopology] ========== 开始应用壁纸 ==========")
        NSLog("[WallpaperTopology] 壁纸: \(wallpaper.name)")
        NSLog("[WallpaperTopology] 显示拓扑: \(settings.displayTopology)")
        NSLog("[WallpaperTopology] 明确指定的屏幕: \(targetScreenId ?? "nil")")

        let screens = displayManager.availableScreens
        guard !screens.isEmpty else { throw WallpaperTopologyError.noScreensAvailable }

        let contentURL = renderedURL ?? Self.resolveURL(from: wallpaper.filePath)
        let resolvedScreenId = resolvedIndependentScreenId(
            settings: settings,
            screens: screens,
            explicitTargetScreenId: targetScreenId
        )

        NSLog("[WallpaperTopology] 解析后的目标屏幕: \(resolvedScreenId ?? "nil")")

        switch settings.displayTopology {
        case .independent:
            guard let resolvedScreenId else { throw WallpaperTopologyError.missingIndependentScreen }
            try await applyIndependent(
                wallpaper: wallpaper,
                contentURL: contentURL,
                targetScreenId: resolvedScreenId,
                effects: effects,
                displayManager: displayManager
            )
            return independentSuccessMessage(for: resolvedScreenId, screens: screens)
        case .mirror:
            try await applyMirror(
                wallpaper: wallpaper,
                contentURL: contentURL,
                effects: effects
            )
            return screens.count > 1 ? "已镜像到所有屏幕" : "设置成功"
        case .panorama:
            try await applyPanorama(
                wallpaper: wallpaper,
                contentURL: contentURL,
                effects: effects,
                displayManager: displayManager
            )
            return screens.count > 1 ? "已按全景模式铺满所有屏幕" : "设置成功"
        }
    }

    func resolvedIndependentScreenId(
        settings: Settings,
        screens: [ScreenInfo] = DisplayManager.shared.availableScreens,
        explicitTargetScreenId: String? = nil
    ) -> String? {
        // 最高优先级：用户明确选择的屏幕（通过对话框）
        if let explicitTargetScreenId, screens.contains(where: { $0.id == explicitTargetScreenId }) {
            NSLog("[WallpaperTopology] ✅ 使用用户明确选择的屏幕: \(explicitTargetScreenId)")
            return explicitTargetScreenId
        }

        // 如果没有明确选择，使用主屏
        if let main = screens.first(where: { $0.isMain }) {
            NSLog("[WallpaperTopology] 使用主屏: \(main.id)")
            return main.id
        }

        // 最后：第一个屏幕
        let firstId = screens.first?.id
        NSLog("[WallpaperTopology] 使用第一个屏幕: \(firstId ?? "nil")")
        return firstId
    }

    func restore(mapping: [String: UUID], context: ModelContext, settings: Settings, displayManager: DisplayManager = .shared) async {
        let screens = displayManager.availableScreens
        guard !screens.isEmpty else { return }

        switch settings.displayTopology {
        case .independent:
            for screen in screens {
                guard let wallpaperId = mapping[screen.id],
                      let wallpaper = fetchWallpaper(id: wallpaperId, context: context) else { continue }
                try? await applyWallpaperToSingleScreen(
                    wallpaper: wallpaper,
                    contentURL: Self.resolveURL(from: wallpaper.filePath),
                    targetScreenId: screen.id,
                    effects: nil,
                    displayManager: displayManager
                )
            }
        case .mirror, .panorama:
            guard let wallpaperId = primaryWallpaperId(from: mapping, screens: screens),
                  let wallpaper = fetchWallpaper(id: wallpaperId, context: context) else { return }
            _ = try? await apply(
                wallpaper: wallpaper,
                renderedURL: nil,
                effects: nil,
                settings: settings,
                displayManager: displayManager
            )
        }
    }

    func sessionMapping(for wallpaperId: UUID, settings: Settings, displayManager: DisplayManager = .shared, targetScreenId: String? = nil) -> [String: UUID] {
        let screens = displayManager.availableScreens
        switch settings.displayTopology {
        case .independent:
            guard let resolvedScreenId = resolvedIndependentScreenId(
                settings: settings,
                screens: screens,
                explicitTargetScreenId: targetScreenId
            ) else {
                NSLog("[WallpaperTopology] ⚠️ sessionMapping: 无法解析目标屏幕")
                return [:]
            }
            var mapping = RestoreManager.shared.loadSession()
            mapping[resolvedScreenId] = wallpaperId
            NSLog("[WallpaperTopology] sessionMapping: 屏幕 \(resolvedScreenId) → 壁纸 \(wallpaperId)")
            return mapping
        case .mirror, .panorama:
            return Dictionary(uniqueKeysWithValues: screens.map { ($0.id, wallpaperId) })
        }
    }

    private func applyIndependent(
        wallpaper: Wallpaper,
        contentURL: URL,
        targetScreenId: String,
        effects: WallpaperRenderEffects?,
        displayManager: DisplayManager
    ) async throws {
        try await applyWallpaperToSingleScreen(
            wallpaper: wallpaper,
            contentURL: contentURL,
            targetScreenId: targetScreenId,
            effects: effects,
            displayManager: displayManager
        )
    }

    private func applyMirror(
        wallpaper: Wallpaper,
        contentURL: URL,
        effects: WallpaperRenderEffects?
    ) async throws {
        switch wallpaper.type {
        case .video:
            try await RenderPipeline.shared.setWallpaper(url: contentURL, wallpaperId: wallpaper.id, effects: effects)
        case .image, .heic:
            // 始终使用 RenderPipeline，以便显示调试信息
            try await RenderPipeline.shared.setImageWallpaper(url: contentURL, wallpaperId: wallpaper.id, effects: effects)
        }
    }

    private func applyPanorama(
        wallpaper: Wallpaper,
        contentURL: URL,
        effects: WallpaperRenderEffects?,
        displayManager: DisplayManager
    ) async throws {
        let screenFrames = displayManager.screenFramesById()
        guard !screenFrames.isEmpty else { throw WallpaperTopologyError.noScreensAvailable }

        switch wallpaper.type {
        case .video:
            try await RenderPipeline.shared.setWallpaper(url: contentURL, wallpaperId: wallpaper.id, effects: effects)
            RenderPipeline.shared.configurePanoramaLayout(screenFrames: screenFrames)
        case .image, .heic:
            RenderPipeline.shared.cleanup()
            let slices = try PanoramaImageRenderer.makeSlices(from: contentURL, screenFrames: screenFrames)
            for (screenId, sliceURL) in slices {
                try await RenderPipeline.shared.setImageWallpaper(
                    url: sliceURL,
                    screenId: screenId,
                    wallpaperId: wallpaper.id,
                    effects: effects
                )
            }
        }
    }

    private func applyWallpaperToSingleScreen(
        wallpaper: Wallpaper,
        contentURL: URL,
        targetScreenId: String,
        effects: WallpaperRenderEffects?,
        displayManager: DisplayManager
    ) async throws {
        switch wallpaper.type {
        case .video:
            try await RenderPipeline.shared.setWallpaper(
                url: contentURL,
                screenId: targetScreenId,
                wallpaperId: wallpaper.id,
                effects: effects
            )
        case .image, .heic:
            // 始终使用 RenderPipeline，以便显示调试信息
            try await RenderPipeline.shared.setImageWallpaper(
                url: contentURL,
                screenId: targetScreenId,
                wallpaperId: wallpaper.id,
                effects: effects
            )
        }
    }

    private func primaryWallpaperId(from mapping: [String: UUID], screens: [ScreenInfo]) -> UUID? {
        for screen in screens {
            if let wallpaperId = mapping[screen.id] {
                return wallpaperId
            }
        }
        return mapping.values.first
    }

    private func fetchWallpaper(id: UUID, context: ModelContext) -> Wallpaper? {
        let descriptor = FetchDescriptor<Wallpaper>(
            predicate: #Predicate { wallpaper in
                wallpaper.id == id
            }
        )
        return try? context.fetch(descriptor).first
    }

    private func independentSuccessMessage(for targetScreenId: String, screens: [ScreenInfo]) -> String {
        let name = screens.first(where: { $0.id == targetScreenId })?.name ?? targetScreenId
        return "已设置到 \(name)"
    }

    private static func resolveURL(from path: String) -> URL {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        return URL(fileURLWithPath: trimmed)
    }
}

enum WallpaperTopologyError: LocalizedError {
    case noScreensAvailable
    case missingIndependentScreen
    case screenUnavailable(String)
    case imageLoadFailed(String)

    var errorDescription: String? {
        switch self {
        case .noScreensAvailable:
            return "未检测到可用显示器"
        case .missingIndependentScreen:
            return "请先选择独立模式的目标屏幕"
        case .screenUnavailable(let screenId):
            return "目标屏幕不可用: \(screenId)"
        case .imageLoadFailed(let path):
            return "无法生成全景壁纸: \(path)"
        }
    }
}

private enum PanoramaImageRenderer {
    static func makeSlices(from sourceURL: URL, screenFrames: [String: CGRect]) throws -> [String: URL] {
        guard let image = NSImage(contentsOf: sourceURL),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw WallpaperTopologyError.imageLoadFailed(sourceURL.path)
        }

        let union = screenFrames.values.reduce(into: CGRect.null) { partial, frame in
            partial = partial.union(frame)
        }
        guard !union.isNull, union.width > 0, union.height > 0 else {
            throw WallpaperTopologyError.noScreensAvailable
        }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let scale = max(union.width / imageSize.width, union.height / imageSize.height)
        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(
            x: (union.width - scaledSize.width) / 2,
            y: (union.height - scaledSize.height) / 2
        )

        var outputs: [String: URL] = [:]
        for (screenId, frame) in screenFrames {
            let relativeFrame = CGRect(
                x: frame.minX - union.minX,
                y: frame.minY - union.minY,
                width: frame.width,
                height: frame.height
            )

            let cropRectInScaledImage = CGRect(
                x: relativeFrame.minX - origin.x,
                y: relativeFrame.minY - origin.y,
                width: relativeFrame.width,
                height: relativeFrame.height
            )

            let pixelCropRect = CGRect(
                x: cropRectInScaledImage.minX / scale,
                y: cropRectInScaledImage.minY / scale,
                width: cropRectInScaledImage.width / scale,
                height: cropRectInScaledImage.height / scale
            )

            let flippedRect = CGRect(
                x: pixelCropRect.minX,
                y: imageSize.height - pixelCropRect.maxY,
                width: pixelCropRect.width,
                height: pixelCropRect.height
            ).integral.intersection(CGRect(origin: .zero, size: imageSize))

            guard let cropped = cgImage.cropping(to: flippedRect),
                  let rep = NSBitmapImageRep(cgImage: cropped).representation(using: .png, properties: [:]) else {
                continue
            }

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("PlumWallPaper-Panorama-\(screenId)-\(UUID().uuidString)")
                .appendingPathExtension("png")
            try rep.write(to: url)
            outputs[screenId] = url
        }
        return outputs
    }
}
