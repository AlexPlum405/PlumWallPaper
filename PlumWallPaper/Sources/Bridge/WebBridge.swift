//
//  WebBridge.swift
//  PlumWallPaper
//
//  Created on 2026-04-28.
//

import Foundation
import WebKit
import SwiftData
import AppKit
import UniformTypeIdentifiers

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

        Task { @MainActor in
            PauseStrategyManager.shared.startMonitoring { [weak self] in
                guard let self else { return [:] }
                let settings = try? self.preferencesStore.fetchSettings()
                return self.serializeSettings(settings ?? Settings())
            }

            // 启动时恢复菜单栏和渲染配置
            if let settings = try? self.preferencesStore.fetchSettings() {
                if settings.menuBarEnabled == true {
                    MenuBarManager.shared.configure(window: NSApp.keyWindow)
                    MenuBarManager.shared.setEnabled(true)
                }
                WallpaperEngine.shared.updateRenderingConfig(colorSpace: settings.colorSpace, performanceMode: settings.vSyncEnabled)
                WallpaperEngine.shared.updateAudioConfig(
                    volume: settings.globalVolume ?? 50,
                    muted: settings.defaultMuted ?? false,
                    previewOnly: settings.previewOnlyAudio ?? false,
                    rate: settings.playbackRate ?? 1.0
                )
                WallpaperEngine.shared.updateWallpaperOpacity(settings.wallpaperOpacity ?? 100)
                WallpaperEngine.shared.updateFPSLimit(settings.fpsLimit ?? 0)
                PerformanceMonitor.shared.startMonitoring()
                AudioDuckingMonitor.shared.startMonitoring(
                    enabled: settings.audioDuckingEnabled && !(settings.previewOnlyAudio ?? false)
                )
            }

            // 启动后静默补全缺失的壁纸帧率元数据
            FrameRateBackfiller.shared.backfillMissingFrameRates(modelContext: self.modelContext)

            // 启动时检查缓存清理
            if let settings = try? self.preferencesStore.fetchSettings(), settings.autoCleanEnabled {
                Task.detached(priority: .background) {
                    ThumbnailGenerator.shared.cleanCacheIfNeeded(threshold: settings.cacheThreshold)
                }
            }
        }
    }

    // MARK: - WKScriptMessageHandler

    nonisolated func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        let body = message.body
        NSLog("[WebBridge] Received message: %@", String(describing: body))
        Task { @MainActor in
            guard let dict = body as? [String: Any],
                  let action = dict["action"] as? String,
                  let callbackId = dict["callbackId"] as? String else {
                NSLog("[WebBridge] Invalid message format")
                return
            }
            NSLog("[WebBridge] Action: %@, CallbackId: %@", action, callbackId)
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

            // 2. selectFiles — 弹出 NSOpenPanel 让用户选择文件，返回路径但不导入
            case "selectFiles":
                return await withCheckedContinuation { continuation in
                    DispatchQueue.main.async {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = true
                        panel.canChooseDirectories = false
                        panel.allowedContentTypes = [.movie, .image]
                        panel.message = "选择要导入的壁纸文件（支持视频和图片）"

                        panel.begin { response in
                            Task { @MainActor in
                                guard response == .OK, !panel.urls.isEmpty else {
                                    continuation.resume(returning: self.fail("User cancelled"))
                                    return
                                }
                                let filePaths = panel.urls.map { ["path": $0.path, "name": $0.deletingPathExtension().lastPathComponent] }
                                continuation.resume(returning: self.success(filePaths))
                            }
                        }
                    }
                }

            // 3. selectFolder — 弹出 NSOpenPanel 选择目录，返回其中的壁纸文件路径但不导入
            case "selectFolder":
                return await withCheckedContinuation { continuation in
                    DispatchQueue.main.async {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        panel.message = "选择包含壁纸文件的目录"

                        panel.begin { response in
                            Task { @MainActor in
                                guard response == .OK, let folderURL = panel.url else {
                                    continuation.resume(returning: self.fail("User cancelled"))
                                    return
                                }
                                do {
                                    let validExts = Set(["mp4", "mov", "m4v", "heic", "heif", "jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif"])
                                    let contents = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
                                    let mediaFiles = contents.filter { validExts.contains($0.pathExtension.lowercased()) }
                                    guard !mediaFiles.isEmpty else {
                                        continuation.resume(returning: self.fail("目录中没有找到支持的壁纸文件"))
                                        return
                                    }
                                    let filePaths = mediaFiles.map { ["path": $0.path, "name": $0.deletingPathExtension().lastPathComponent] }
                                    continuation.resume(returning: self.success(filePaths))
                                } catch {
                                    continuation.resume(returning: self.fail(error.localizedDescription))
                                }
                            }
                        }
                    }
                }

            // 4. importFiles — 根据路径导入文件
            case "importFiles":
                guard let paths = params["paths"] as? [String] else {
                    return fail("Missing paths parameter")
                }
                let urls = paths.map { URL(fileURLWithPath: $0) }
                let imported = try await FileImporter.shared.importFiles(urls: urls)

                let customName = params["name"] as? String
                let tagName = params["tag"] as? String
                let favorite = params["favorite"] as? Bool ?? false

                for (index, wallpaper) in imported.enumerated() {
                    // 自定义名称
                    if let customName = customName, !customName.isEmpty {
                        wallpaper.name = imported.count > 1 ? "\(customName) (\(index + 1))" : customName
                    }

                    // 重复检测：如果 fileHash 已存在，自动追加序号
                    if try wallpaperStore.wallpaperExists(fileHash: wallpaper.fileHash) {
                        var suffix = 2
                        let baseName = wallpaper.name
                        while try wallpaperStore.nameExists(baseName + " (\(suffix))") {
                            suffix += 1
                        }
                        wallpaper.name = "\(baseName) (\(suffix))"
                    }

                    wallpaper.isFavorite = favorite

                    if let tagName = tagName, !tagName.isEmpty {
                        let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.name == tagName })
                        let existingTag = try? modelContext.fetch(descriptor).first
                        let tag = existingTag ?? {
                            let newTag = Tag(name: tagName, color: nil)
                            modelContext.insert(newTag)
                            return newTag
                        }()
                        wallpaper.tags.append(tag)
                    }
                }

                try wallpaperStore.addWallpapers(imported)
                SlideshowScheduler.shared.rebuildPlaylist()
                return success(imported.map { serializeWallpaper($0) })

            // 5. setWallpaper
            case "setWallpaper":
                let wallpaper = try resolveWallpaper(params)

                // 同步渲染配置
                let settings = try preferencesStore.fetchSettings()
                WallpaperEngine.shared.updateRenderingConfig(colorSpace: settings.colorSpace, performanceMode: settings.vSyncEnabled)

                let mode = params["mode"] as? String
                var affectedScreens: [String] = []

                if let screenId = params["screenId"] as? String {
                    guard let screenInfo = DisplayManager.shared.availableScreens.first(where: { $0.id == screenId }) else {
                        return fail("Screen not found")
                    }
                    WallpaperEngine.shared.setWallpaper(wallpaper, for: screenInfo)
                    affectedScreens = [screenId]
                } else if mode == "panorama" {
                    WallpaperEngine.shared.setWallpaperPanorama(wallpaper, screenOrder: settings.screenOrder)
                    affectedScreens = DisplayManager.shared.availableScreens.map { $0.id }
                } else {
                    WallpaperEngine.shared.setWallpaperToAllScreens(wallpaper)
                    affectedScreens = DisplayManager.shared.availableScreens.map { $0.id }
                }

                wallpaper.lastUsedDate = Date()
                try wallpaperStore.updateWallpaper()

                // 持久化壁纸选择，启动时自动恢复
                var mapping = RestoreManager.shared.loadSession()
                for screenId in affectedScreens {
                    mapping[screenId] = wallpaper.id
                }
                RestoreManager.shared.saveSession(mapping: mapping)

                return success([:] as [String: Any])

            // 4. toggleFavorite
            case "toggleFavorite":
                let wallpaper = try resolveWallpaper(params)
                wallpaper.isFavorite.toggle()
                try wallpaperStore.updateWallpaper()
                SlideshowScheduler.shared.rebuildPlaylist()
                return success(["isFavorite": wallpaper.isFavorite])

            // 5. deleteWallpaper
            case "deleteWallpaper":
                let wallpaper = try resolveWallpaper(params)
                try wallpaperStore.deleteWallpaper(wallpaper)
                SlideshowScheduler.shared.rebuildPlaylist()
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

            // 8.5. getAvailableScreens
            case "getAvailableScreens":
                let screens = NSScreen.screens.enumerated().map { (index, screen) -> [String: Any] in
                    let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? Int ?? index
                    return [
                        "id": String(id),
                        "name": screen.localizedName,
                        "isMain": screen == NSScreen.main
                    ]
                }
                return success(["screens": screens])

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
                let oldColorSpace = settings.colorSpace
                let oldPerformanceMode = settings.vSyncEnabled
                let oldVolume = settings.globalVolume
                let oldMuted = settings.defaultMuted
                let oldPreviewOnly = settings.previewOnlyAudio
                let oldRate = settings.playbackRate
                let oldOpacity = settings.wallpaperOpacity
                let oldFpsLimit = settings.fpsLimit
                let oldLoopMode = settings.loopMode
                let oldAudioScreenId = settings.audioScreenId
                let oldRandomStartPosition = settings.randomStartPosition
                let oldSlideshowEnabled = settings.slideshowEnabled
                let oldSlideshowInterval = settings.slideshowInterval
                let oldSlideshowOrder = settings.slideshowOrder
                let oldSlideshowSource = settings.slideshowSource
                let oldSlideshowTagId = settings.slideshowTagId
                let oldDucking = settings.audioDuckingEnabled
                applySettingsUpdate(settings, from: settingsData)
                try preferencesStore.updateSettings()

                // 渲染相关设置变化时即时重载
                if settings.colorSpace != oldColorSpace || settings.vSyncEnabled != oldPerformanceMode {
                    WallpaperEngine.shared.updateRenderingConfig(colorSpace: settings.colorSpace, performanceMode: settings.vSyncEnabled)
                    WallpaperEngine.shared.reloadAllRenderers()
                }

                // 播放速率变化
                if settings.playbackRate != oldRate {
                    WallpaperEngine.shared.updatePlaybackRate(settings.playbackRate ?? 1.0)
                }

                // 全局音量变化
                if settings.globalVolume != oldVolume {
                    WallpaperEngine.shared.updateGlobalVolume(settings.globalVolume ?? 50)
                }

                // 静音策略变化
                if settings.defaultMuted != oldMuted || settings.previewOnlyAudio != oldPreviewOnly {
                    WallpaperEngine.shared.updateMutingPolicy(
                        defaultMuted: settings.defaultMuted ?? false,
                        previewOnly: settings.previewOnlyAudio ?? false,
                        audioScreenId: settings.audioScreenId
                    )
                }

                // 循环模式变化（需要重建渲染器）
                if settings.loopMode != oldLoopMode {
                    WallpaperEngine.shared.loopMode = (settings.loopMode ?? .loop).rawValue
                    WallpaperEngine.shared.reloadAllRenderers()
                }

                // 随机起始位置
                if settings.randomStartPosition != oldRandomStartPosition {
                    WallpaperEngine.shared.randomStartPosition = settings.randomStartPosition ?? false
                }

                // 音频输出屏幕变化
                if settings.audioScreenId != oldAudioScreenId {
                    WallpaperEngine.shared.updateAudioScreenMuting(audioScreenId: settings.audioScreenId)
                }

                // 壁纸不透明度变化时即时更新（无需重载）
                if settings.wallpaperOpacity != oldOpacity {
                    WallpaperEngine.shared.updateWallpaperOpacity(settings.wallpaperOpacity ?? 100)
                }

                // FPS 上限变化时即时更新（无需重载）
                if settings.fpsLimit != oldFpsLimit {
                    WallpaperEngine.shared.updateFPSLimit(settings.fpsLimit ?? 0)
                }

                // 音频闪避变化
                if settings.audioDuckingEnabled != oldDucking || settings.previewOnlyAudio != oldPreviewOnly {
                    AudioDuckingMonitor.shared.startMonitoring(
                        enabled: settings.audioDuckingEnabled && !(settings.previewOnlyAudio ?? false)
                    )
                }

                // 轮播启用/禁用
                if settings.slideshowEnabled != oldSlideshowEnabled {
                    if settings.slideshowEnabled {
                        AppViewModel().setupSlideshow()
                        SlideshowScheduler.shared.start(context: modelContext, settings: settings)
                    } else {
                        SlideshowScheduler.shared.stop()
                    }
                }

                // 轮播参数变化（间隔、顺序、来源、标签）
                if settings.slideshowEnabled {
                    if settings.slideshowInterval != oldSlideshowInterval {
                        SlideshowScheduler.shared.updateInterval(settings.slideshowInterval)
                    }
                    if settings.slideshowOrder != oldSlideshowOrder ||
                       settings.slideshowSource != oldSlideshowSource ||
                       settings.slideshowTagId != oldSlideshowTagId {
                        SlideshowScheduler.shared.rebuildPlaylist()
                    }
                }

                // 暂停策略相关设置变更时立即重新评估
                PauseStrategyManager.shared.reevaluate()

                return success([:] as [String: Any])

            // 11. setWallpaperVolume
            case "setWallpaperVolume":
                guard let wallpaperIdStr = params["wallpaperId"] as? String,
                      let wallpaperId = UUID(uuidString: wallpaperIdStr),
                      let volume = params["volume"] as? Int else {
                    return fail("Missing wallpaperId or volume")
                }
                let descriptor = FetchDescriptor<Wallpaper>(predicate: #Predicate { $0.id == wallpaperId })
                guard let wallpaper = try modelContext.fetch(descriptor).first else {
                    return fail("Wallpaper not found")
                }
                wallpaper.volumeOverride = volume
                try modelContext.save()
                WallpaperEngine.shared.updateWallpaperVolume(wallpaperId: wallpaperId)
                return success([:] as [String: Any])

            // 12. getTags
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

            case "revealInFinder":
                let wallpaper = try resolveWallpaper(params)
                let fileURL = URL(fileURLWithPath: wallpaper.filePath)
                NSWorkspace.shared.activateFileViewerSelecting([fileURL])
                return success([:] as [String: Any])

            case "checkDuplicates":
                guard let paths = params["paths"] as? [String] else {
                    return fail("Missing paths parameter")
                }
                let urls = paths.map { URL(fileURLWithPath: $0) }
                var duplicates: [[String: Any]] = []
                for url in urls {
                    let hash = try await FileImporter.shared.quickHash(url: url)
                    if try wallpaperStore.wallpaperExists(fileHash: hash) {
                        let existingName = try wallpaperStore.findNameByHash(hash) ?? url.deletingPathExtension().lastPathComponent
                        duplicates.append([
                            "path": url.path,
                            "name": url.deletingPathExtension().lastPathComponent,
                            "existingName": existingName
                        ])
                    }
                }
                return success(duplicates)

            case "selectLibraryPath":
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.canCreateDirectories = true
                panel.allowsMultipleSelection = false
                panel.message = "选择壁纸资源库存储位置"

                if let window = NSApp.keyWindow {
                    let response = await panel.beginSheetModal(for: window)
                    if response == .OK, let url = panel.url {
                        let newPath = url.path
                        let settings = try preferencesStore.fetchSettings()
                        let oldPath = settings.libraryPath

                        if oldPath != newPath {
                            let fm = FileManager.default
                            try? fm.createDirectory(atPath: newPath, withIntermediateDirectories: true)

                            let descriptor = FetchDescriptor<Wallpaper>()
                            let wallpapers = try modelContext.fetch(descriptor)
                            var movedCount = 0
                            var failedFiles: [String] = []

                            for wallpaper in wallpapers {
                                let oldFile = URL(fileURLWithPath: wallpaper.filePath)
                                guard oldFile.path.hasPrefix(oldPath) else { continue }

                                var relativePath = String(oldFile.path.dropFirst(oldPath.count))
                                if relativePath.hasPrefix("/") {
                                    relativePath = String(relativePath.dropFirst())
                                }

                                let newFile = URL(fileURLWithPath: newPath).appendingPathComponent(relativePath)
                                let newDir = newFile.deletingLastPathComponent()

                                do {
                                    try fm.createDirectory(at: newDir, withIntermediateDirectories: true)
                                    if fm.fileExists(atPath: oldFile.path) {
                                        if fm.fileExists(atPath: newFile.path) {
                                            try fm.removeItem(at: newFile)
                                        }
                                        try fm.moveItem(at: oldFile, to: newFile)
                                        wallpaper.filePath = newFile.path
                                        movedCount += 1
                                    }
                                } catch {
                                    failedFiles.append(oldFile.lastPathComponent)
                                }
                            }

                            if movedCount > 0 {
                                try modelContext.save()
                            }

                            if !failedFiles.isEmpty {
                                return fail("部分文件迁移失败: \(failedFiles.joined(separator: ", "))")
                            }

                            return success(["path": newPath, "migrated": true, "movedCount": movedCount] as [String: Any])
                        }

                        return success(["path": newPath, "migrated": false] as [String: Any])
                    }
                }
                return success([:] as [String: Any])

            case "openURL":
                guard let urlString = params["url"] as? String,
                      let url = URL(string: urlString) else {
                    return fail("Invalid URL parameter")
                }
                NSWorkspace.shared.open(url)
                return success([:] as [String: Any])

            case "getAppInfo":
                let bundle = Bundle.main
                let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                let build = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                let osVersion = ProcessInfo.processInfo.operatingSystemVersion
                let osString = "macOS \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
                var chip = "Unknown"
                var sysInfo = utsname()
                uname(&sysInfo)
                let machine = withUnsafePointer(to: &sysInfo.machine) {
                    $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
                }
                if machine.contains("arm64") {
                    chip = "Apple Silicon"
                } else {
                    chip = "Intel"
                }
                return success([
                    "version": version,
                    "build": build,
                    "os": osString,
                    "chip": chip
                ] as [String: Any])

            case "getLaunchAtLogin":
                return success(["enabled": LaunchAtLoginManager.shared.isEnabled])

            case "setLaunchAtLogin":
                let enabled = params["enabled"] as? Bool ?? false
                LaunchAtLoginManager.shared.setEnabled(enabled)
                return success(["enabled": LaunchAtLoginManager.shared.isEnabled])

            case "getMenuBarEnabled":
                return success(["enabled": MenuBarManager.shared.isEnabled])

            case "setMenuBarEnabled":
                let enabled = params["enabled"] as? Bool ?? false
                MenuBarManager.shared.configure(window: NSApp.keyWindow)
                MenuBarManager.shared.setEnabled(enabled)
                return success(["enabled": MenuBarManager.shared.isEnabled])

            case "getPerformanceMetrics":
                let metrics = PerformanceMonitor.shared.getCurrentMetrics()
                return success(metrics)

            case "getScreenRefreshRates":
                let rates = DisplayManager.shared.getRefreshRates()
                let maxRate = DisplayManager.shared.getMaxRefreshRate()
                return success(["rates": rates, "maxRate": maxRate] as [String: Any])

            case "selectApplication":
                let panel = NSOpenPanel()
                panel.canChooseFiles = true
                panel.canChooseDirectories = false
                panel.allowsMultipleSelection = false
                panel.directoryURL = URL(fileURLWithPath: "/Applications")
                panel.allowedContentTypes = [.application]
                panel.message = "选择要添加规则的应用"

                if let window = NSApp.keyWindow {
                    let response = await panel.beginSheetModal(for: window)
                    if response == .OK, let url = panel.url {
                        let bundle = Bundle(url: url)
                        let bundleId = bundle?.bundleIdentifier ?? url.deletingPathExtension().lastPathComponent
                        let appName = url.deletingPathExtension().lastPathComponent
                        return success(["bundleIdentifier": bundleId, "appName": appName] as [String: Any])
                    }
                }
                return success([:] as [String: Any])

            case "getPauseReason":
                let reason = PauseStrategyManager.shared.pauseReason
                return success(["reason": reason ?? "", "isPaused": reason != nil] as [String: Any])

            case "resumeTemporarily":
                PauseStrategyManager.shared.resumeTemporarily()
                return success([:] as [String: Any])

            case "slideshowNext":
                SlideshowScheduler.shared.next()
                return success([:] as [String: Any])

            case "slideshowPrev":
                SlideshowScheduler.shared.prev()
                return success([:] as [String: Any])

            case "getSlideshowStatus":
                let status = SlideshowScheduler.shared.getStatus()
                return success([
                    "current": status.current,
                    "total": status.total,
                    "nextIn": status.nextIn
                ])

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
        NSLog("[WebBridge] resolveWallpaper params: %@", String(describing: params))
        guard let wallpaperId = params["wallpaperId"] as? String else {
            NSLog("[WebBridge] Missing wallpaperId in params")
            throw BridgeError.missingParameter("wallpaperId")
        }
        NSLog("[WebBridge] wallpaperId string: %@", wallpaperId)
        guard let uuid = UUID(uuidString: wallpaperId) else {
            NSLog("[WebBridge] Invalid UUID format: %@", wallpaperId)
            throw BridgeError.missingParameter("wallpaperId")
        }
        NSLog("[WebBridge] Parsed UUID: %@", uuid.uuidString)
        let descriptor = FetchDescriptor<Wallpaper>(predicate: #Predicate { $0.id == uuid })
        let results = try modelContext.fetch(descriptor)
        NSLog("[WebBridge] Found %d wallpapers matching UUID", results.count)
        guard let wallpaper = results.first else {
            NSLog("[WebBridge] Wallpaper not found for UUID: %@", uuid.uuidString)
            throw BridgeError.notFound("Wallpaper not found")
        }
        NSLog("[WebBridge] Resolved wallpaper: %@ (id: %@)", wallpaper.name, wallpaper.id.uuidString)
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
            "filePath": URL(fileURLWithPath: w.filePath).absoluteString,
            "type": w.type.rawValue,
            "resolution": w.resolution,
            "fileSize": w.fileSize,
            "thumbnailPath": URL(fileURLWithPath: w.thumbnailPath).absoluteString,
            "isFavorite": w.isFavorite,
            "importDate": dateFormatter.string(from: w.importDate),
            "tags": w.tags.map { serializeTag($0) },
            "hasAudio": w.hasAudio ?? false
        ]
        if let duration = w.duration { dict["duration"] = duration }
        if let frameRate = w.frameRate { dict["frameRate"] = frameRate }
        if let vol = w.volumeOverride { dict["volumeOverride"] = vol }
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
            "animationsEnabled": s.animationsEnabled,
            "globalVolume": s.globalVolume ?? 50,
            "defaultMuted": s.defaultMuted ?? false,
            "previewOnlyAudio": s.previewOnlyAudio ?? false,
            "playbackRate": s.playbackRate ?? 1.0,
            "wallpaperOpacity": s.wallpaperOpacity ?? 100,
            "launchAtLogin": s.launchAtLogin ?? LaunchAtLoginManager.shared.isEnabled,
            "menuBarEnabled": s.menuBarEnabled ?? MenuBarManager.shared.isEnabled,
            "screenOrder": s.screenOrder ?? [] as [String],
            "fpsLimit": s.fpsLimit ?? 0,
            "loopMode": (s.loopMode ?? .loop).rawValue,
            "randomStartPosition": s.randomStartPosition ?? false,
            "audioScreenId": s.audioScreenId as Any,
            "slideshowSource": (s.slideshowSource ?? .all).rawValue,
            "slideshowTagId": s.slideshowTagId as Any,
            "appRules": s.appRules.map { ["id": $0.id, "bundleIdentifier": $0.bundleIdentifier, "appName": $0.appName, "action": $0.action.rawValue] }
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
        if let v = d["globalVolume"] as? Int { s.globalVolume = v }
        if let v = d["defaultMuted"] as? Bool { s.defaultMuted = v }
        if let v = d["previewOnlyAudio"] as? Bool { s.previewOnlyAudio = v }
        if let v = d["playbackRate"] as? Double { s.playbackRate = v }
        if let v = d["wallpaperOpacity"] as? Int { s.wallpaperOpacity = v }
        if let v = d["screenOrder"] as? [String] { s.screenOrder = v }
        if let v = d["fpsLimit"] as? Int { s.fpsLimit = v == 0 ? nil : v }
        if let v = d["loopMode"] as? String, let mode = LoopMode(rawValue: v) { s.loopMode = mode }
        if let v = d["randomStartPosition"] as? Bool { s.randomStartPosition = v }
        if let v = d["audioScreenId"] as? String { s.audioScreenId = v }
        if d["audioScreenId"] is NSNull { s.audioScreenId = nil }
        if let v = d["slideshowSource"] as? String, let source = SlideshowSource(rawValue: v) { s.slideshowSource = source }
        if let v = d["slideshowTagId"] as? String { s.slideshowTagId = v }
        if d["slideshowTagId"] is NSNull { s.slideshowTagId = nil }
        if let v = d["appRules"] as? [[String: Any]] {
            s.appRules = v.compactMap { dict in
                guard let bundleId = dict["bundleIdentifier"] as? String,
                      let appName = dict["appName"] as? String,
                      let actionStr = dict["action"] as? String,
                      let action = RuleAction(rawValue: actionStr) else { return nil }
                let id = dict["id"] as? String ?? UUID().uuidString
                return AppRule(id: id, bundleIdentifier: bundleId, appName: appName, action: action)
            }
        }
        if let v = d["launchAtLogin"] as? Bool {
            s.launchAtLogin = v
            LaunchAtLoginManager.shared.setEnabled(v)
        }
        if let v = d["menuBarEnabled"] as? Bool {
            s.menuBarEnabled = v
            MenuBarManager.shared.configure(window: NSApp.keyWindow)
            MenuBarManager.shared.setEnabled(v)
        }
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
