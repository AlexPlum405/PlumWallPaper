//
//  WebBridge.swift
//  PlumWallPaper
//
//  Created on 2026-04-28.
//

import Foundation
import WebKit
import SwiftData

/// JS → Swift 路由层
/// 接收来自 WKWebView 的消息，路由到对应的 Swift 后端服务，并将结果回传给 JS。
@MainActor
final class WebBridge: NSObject, WKScriptMessageHandler {
    private let modelContext: ModelContext
    private let wallpaperStore: WallpaperStore
    private let preferencesStore: PreferencesStore
    private weak var webView: WKWebView?

    private let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    init(modelContext: ModelContext, webView: WKWebView) {
        self.modelContext = modelContext
        self.wallpaperStore = WallpaperStore(modelContext: modelContext)
        self.preferencesStore = PreferencesStore(modelContext: modelContext)
        self.webView = webView
        super.init()
    }

    // MARK: - WKScriptMessageHandler

    nonisolated func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        let body = message.body
        Task { @MainActor in
            guard let dict = body as? [String: Any],
                  let action = dict["action"] as? String,
                  let callbackId = dict["callbackId"] as? String else {
                return
            }
            let result = await handleAction(action, params: dict)
            sendCallback(callbackId: callbackId, result: result)
        }
    }

    // MARK: - Action Router

    private func handleAction(_ action: String, params: [String: Any]) async -> [String: Any] {
        do {
            switch action {
            // 1. getWallpapers
            case "getWallpapers":
                let wallpapers = try wallpaperStore.fetchAllWallpapers()
                return success(wallpapers.map { serializeWallpaper($0) })

            // 2. importFiles
            case "importFiles":
                guard let paths = params["paths"] as? [String] else {
                    return fail("Missing paths parameter")
                }
                let urls = paths.map { URL(fileURLWithPath: $0) }
                let imported = try await FileImporter.shared.importFiles(urls: urls)
                try wallpaperStore.addWallpapers(imported)
                return success(imported.map { serializeWallpaper($0) })

            // 3. setWallpaper
            case "setWallpaper":
                let (wallpaper, screenInfo) = try resolveWallpaperAndScreen(params)
                WallpaperEngine.shared.setWallpaper(wallpaper, for: screenInfo)
                wallpaper.lastUsedDate = Date()
                try wallpaperStore.updateWallpaper()
                return success([:] as [String: Any])

            // 4. toggleFavorite
            case "toggleFavorite":
                let wallpaper = try resolveWallpaper(params)
                wallpaper.isFavorite.toggle()
                try wallpaperStore.updateWallpaper()
                return success(["isFavorite": wallpaper.isFavorite])

            // 5. deleteWallpaper
            case "deleteWallpaper":
                let wallpaper = try resolveWallpaper(params)
                try wallpaperStore.deleteWallpaper(wallpaper)
                return success([:] as [String: Any])

            // 6. applyFilter
            case "applyFilter":
                let wallpaper = try resolveWallpaper(params)
                guard let filterData = params["filter"] as? [String: Any] else {
                    return fail("Missing filter parameter")
                }
                let preset = deserializeFilterPreset(filterData)
                modelContext.insert(preset)
                wallpaper.filterPreset = preset
                try wallpaperStore.updateWallpaper()
                WallpaperEngine.shared.applyFilter(preset, to: wallpaper)
                return success([:] as [String: Any])
            // 7. removeFilter
            case "removeFilter":
                let wallpaper = try resolveWallpaper(params)
                wallpaper.filterPreset = nil
                try wallpaperStore.updateWallpaper()
                return success([:] as [String: Any])

            // 8. getScreens
            case "getScreens":
                DisplayManager.shared.refreshScreens()
                let screens = DisplayManager.shared.availableScreens.map { s -> [String: Any] in
                    ["id": s.id, "name": s.name, "resolution": s.resolution, "isMain": s.isMain]
                }
                return success(screens)

            // 9. getSettings
            case "getSettings":
                let settings = try preferencesStore.fetchSettings()
                return success(serializeSettings(settings))

            // 10. updateSettings
            case "updateSettings":
                guard let settingsData = params["settings"] as? [String: Any] else {
                    return fail("Missing settings parameter")
                }
                let settings = try preferencesStore.fetchSettings()
                applySettingsUpdate(settings, from: settingsData)
                try preferencesStore.updateSettings()
                return success([:] as [String: Any])

            // 11. getTags
            case "getTags":
                let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
                let tags = try modelContext.fetch(descriptor)
                return success(tags.map { serializeTag($0) })

            // 12. createTag
            case "createTag":
                guard let name = params["name"] as? String else {
                    return fail("Missing name parameter")
                }
                let color = params["color"] as? String
                let tag = Tag(name: name, color: color)
                modelContext.insert(tag)
                try modelContext.save()
                return success(serializeTag(tag))

            // 13. deleteTag
            case "deleteTag":
                guard let tagId = params["tagId"] as? String,
                      let uuid = UUID(uuidString: tagId) else {
                    return fail("Missing or invalid tagId")
                }
                let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.id == uuid })
                guard let tag = try modelContext.fetch(descriptor).first else {
                    return fail("Tag not found")
                }
                modelContext.delete(tag)
                try modelContext.save()
                return success([:] as [String: Any])


            default:
                return fail("Unknown action: \(action)")
            }
        } catch {
            return fail(error.localizedDescription)
        }
    }

    // MARK: - Helpers

    private static let callbackIdPattern = /^cb_[0-9]+_[a-z0-9]+$/

    private func resolveWallpaper(_ params: [String: Any]) throws -> Wallpaper {
        guard let wallpaperId = params["wallpaperId"] as? String,
              let uuid = UUID(uuidString: wallpaperId) else {
            throw BridgeError.missingParameter("wallpaperId")
        }
        let descriptor = FetchDescriptor<Wallpaper>(predicate: #Predicate { $0.id == uuid })
        guard let wallpaper = try modelContext.fetch(descriptor).first else {
            throw BridgeError.notFound("Wallpaper not found")
        }
        return wallpaper
    }

    private func resolveWallpaperAndScreen(_ params: [String: Any]) throws -> (Wallpaper, ScreenInfo) {
        let wallpaper = try resolveWallpaper(params)
        guard let screenId = params["screenId"] as? String else {
            throw BridgeError.missingParameter("screenId")
        }
        guard let screenInfo = DisplayManager.shared.availableScreens.first(where: { $0.id == screenId }) else {
            throw BridgeError.notFound("Screen not found")
        }
        return (wallpaper, screenInfo)
    }

    private func success<T>(_ data: T) -> [String: Any] {
        ["success": true, "data": data]
    }

    private func fail(_ message: String) -> [String: Any] {
        ["success": false, "error": message]
    }

    private func sendCallback(callbackId: String, result: [String: Any]) {
        guard callbackId.wholeMatch(of: Self.callbackIdPattern) != nil else {
            let errorResult: [String: Any] = ["success": false, "error": "Invalid callbackId format"]
            if let data = try? JSONSerialization.data(withJSONObject: errorResult),
               let json = String(data: data, encoding: .utf8) {
                webView?.evaluateJavaScript("console.error('WebBridge: invalid callbackId', \(json));")
            }
            return
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: result)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw BridgeError.serializationFailed("Failed to encode JSON as UTF-8")
            }
            let script = "window.__bridgeCallback('\(callbackId)', \(jsonString));"
            webView?.evaluateJavaScript(script)
        } catch {
            let fallback = "window.__bridgeCallback('\(callbackId)', {\"success\":false,\"error\":\"Serialization failed\"});"
            webView?.evaluateJavaScript(fallback)
        }
    }

    // MARK: - Serialization

    private func serializeWallpaper(_ w: Wallpaper) -> [String: Any] {
        var dict: [String: Any] = [
            "id": w.id.uuidString,
            "name": w.name,
            "filePath": w.filePath,
            "type": w.type.rawValue,
            "resolution": w.resolution,
            "fileSize": w.fileSize,
            "thumbnailPath": w.thumbnailPath,
            "isFavorite": w.isFavorite,
            "importDate": dateFormatter.string(from: w.importDate),
            "tags": w.tags.map { serializeTag($0) }
        ]
        if let duration = w.duration { dict["duration"] = duration }
        if let lastUsed = w.lastUsedDate { dict["lastUsedDate"] = dateFormatter.string(from: lastUsed) }
        if let fp = w.filterPreset { dict["filterPreset"] = serializeFilterPreset(fp) }
        return dict
    }

    private func serializeTag(_ tag: Tag) -> [String: Any] {
        var dict: [String: Any] = ["id": tag.id.uuidString, "name": tag.name]
        if let color = tag.color { dict["color"] = color }
        return dict
    }

    private func serializeFilterPreset(_ p: FilterPreset) -> [String: Any] {
        [
            "id": p.id.uuidString, "name": p.name,
            "exposure": p.exposure, "contrast": p.contrast,
            "saturation": p.saturation, "hue": p.hue,
            "blur": p.blur, "grain": p.grain,
            "vignette": p.vignette, "grayscale": p.grayscale,
            "invert": p.invert
        ]
    }

    private func serializeSettings(_ s: Settings) -> [String: Any] {
        [
            "slideshowEnabled": s.slideshowEnabled,
            "slideshowInterval": s.slideshowInterval,
            "slideshowOrder": s.slideshowOrder.rawValue,
            "transitionEffect": s.transitionEffect.rawValue,
            "vSyncEnabled": s.vSyncEnabled,
            "preDecodeEnabled": s.preDecodeEnabled,
            "audioDuckingEnabled": s.audioDuckingEnabled,
            "pauseOnBattery": s.pauseOnBattery,
            "pauseOnFullscreen": s.pauseOnFullscreen,
            "pauseOnOcclusion": s.pauseOnOcclusion,
            "pauseOnLowBattery": s.pauseOnLowBattery,
            "pauseOnScreenSharing": s.pauseOnScreenSharing,
            "pauseOnLidClosed": s.pauseOnLidClosed,
            "pauseOnHighLoad": s.pauseOnHighLoad,
            "pauseOnLostFocus": s.pauseOnLostFocus,
            "pauseBeforeSleep": s.pauseBeforeSleep,
            "displayTopology": s.displayTopology.rawValue,
            "colorSpace": s.colorSpace.rawValue,
            "libraryPath": s.libraryPath,
            "cacheThreshold": s.cacheThreshold,
            "autoCleanEnabled": s.autoCleanEnabled,
            "themeMode": s.themeMode.rawValue,
            "accentColor": s.accentColor,
            "thumbnailSize": s.thumbnailSize.rawValue,
            "animationsEnabled": s.animationsEnabled
        ]
    }
    // MARK: - Deserialization

    private func deserializeFilterPreset(_ d: [String: Any]) -> FilterPreset {
        FilterPreset(
            name: d["name"] as? String ?? "Custom",
            exposure: d["exposure"] as? Double ?? 100,
            contrast: d["contrast"] as? Double ?? 100,
            saturation: d["saturation"] as? Double ?? 100,
            hue: d["hue"] as? Double ?? 0,
            blur: d["blur"] as? Double ?? 0,
            grain: d["grain"] as? Double ?? 0,
            vignette: d["vignette"] as? Double ?? 0,
            grayscale: d["grayscale"] as? Double ?? 0,
            invert: d["invert"] as? Double ?? 0
        )
    }

    private func applySettingsUpdate(_ s: Settings, from d: [String: Any]) {
        if let v = d["slideshowEnabled"] as? Bool { s.slideshowEnabled = v }
        if let v = d["slideshowInterval"] as? TimeInterval { s.slideshowInterval = v }
        if let v = d["slideshowOrder"] as? String, let e = SlideshowOrder(rawValue: v) { s.slideshowOrder = e }
        if let v = d["transitionEffect"] as? String, let e = TransitionEffect(rawValue: v) { s.transitionEffect = e }
        if let v = d["vSyncEnabled"] as? Bool { s.vSyncEnabled = v }
        if let v = d["preDecodeEnabled"] as? Bool { s.preDecodeEnabled = v }
        if let v = d["audioDuckingEnabled"] as? Bool { s.audioDuckingEnabled = v }
        if let v = d["pauseOnBattery"] as? Bool { s.pauseOnBattery = v }
        if let v = d["pauseOnFullscreen"] as? Bool { s.pauseOnFullscreen = v }
        if let v = d["pauseOnOcclusion"] as? Bool { s.pauseOnOcclusion = v }
        if let v = d["pauseOnLowBattery"] as? Bool { s.pauseOnLowBattery = v }
        if let v = d["pauseOnScreenSharing"] as? Bool { s.pauseOnScreenSharing = v }
        if let v = d["pauseOnLidClosed"] as? Bool { s.pauseOnLidClosed = v }
        if let v = d["pauseOnHighLoad"] as? Bool { s.pauseOnHighLoad = v }
        if let v = d["pauseOnLostFocus"] as? Bool { s.pauseOnLostFocus = v }
        if let v = d["pauseBeforeSleep"] as? Bool { s.pauseBeforeSleep = v }
        if let v = d["displayTopology"] as? String, let e = DisplayTopology(rawValue: v) { s.displayTopology = e }
        if let v = d["colorSpace"] as? String, let e = ColorSpace(rawValue: v) { s.colorSpace = e }
        if let v = d["libraryPath"] as? String { s.libraryPath = v }
        if let v = d["cacheThreshold"] as? Int64 { s.cacheThreshold = v }
        if let v = d["autoCleanEnabled"] as? Bool { s.autoCleanEnabled = v }
        if let v = d["themeMode"] as? String, let e = ThemeMode(rawValue: v) { s.themeMode = e }
        if let v = d["accentColor"] as? String { s.accentColor = v }
        if let v = d["thumbnailSize"] as? String, let e = ThumbnailSize(rawValue: v) { s.thumbnailSize = e }
        if let v = d["animationsEnabled"] as? Bool { s.animationsEnabled = v }
    }
}

// MARK: - Error Type

private enum BridgeError: LocalizedError {
    case missingParameter(String)
    case notFound(String)
    case serializationFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingParameter(let name): return "Missing parameter: \(name)"
        case .notFound(let message): return message
        case .serializationFailed(let message): return message
        }
    }
}
