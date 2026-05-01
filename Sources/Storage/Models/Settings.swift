// Sources/Storage/Models/Settings.swift
import Foundation
import SwiftData

@Model
final class Settings {
    var slideshowEnabled: Bool
    var slideshowInterval: Double
    var slideshowOrder: SlideshowOrder
    var slideshowSource: SlideshowSource
    var slideshowTagId: String?
    var transitionEffect: TransitionEffect
    var loopMode: LoopMode
    var playbackRate: Double
    var randomStartPosition: Bool
    var globalVolume: Int
    var defaultMuted: Bool
    var previewOnlyAudio: Bool
    var audioDuckingEnabled: Bool
    var audioScreenId: String?
    var fpsLimit: Int?
    var vSyncEnabled: Bool
    var pauseOnBattery: Bool
    var pauseOnFullscreen: Bool
    var pauseOnLowBattery: Bool
    var lowBatteryThreshold: Int
    var pauseOnScreenSharing: Bool
    var pauseOnHighLoad: Bool
    var pauseOnLostFocus: Bool
    var pauseOnLidClosed: Bool
    var pauseBeforeSleep: Bool
    var pauseOnOcclusion: Bool
    var displayTopology: DisplayTopology
    var colorSpace: ColorSpaceOption
    var screenOrder: [String]?
    var themeMode: ThemeMode
    var thumbnailSize: ThumbnailSize
    var animationsEnabled: Bool
    var launchAtLogin: Bool
    var menuBarEnabled: Bool
    var libraryPath: String
    var wallpaperOpacity: Int
    var appRulesJSON: String?

    init() {
        self.slideshowEnabled = false
        self.slideshowInterval = 1800
        self.slideshowOrder = .sequential
        self.slideshowSource = .all
        self.transitionEffect = .fade
        self.loopMode = .loop
        self.playbackRate = 1.0
        self.randomStartPosition = false
        self.globalVolume = 100
        self.defaultMuted = false
        self.previewOnlyAudio = false
        self.audioDuckingEnabled = true
        self.fpsLimit = nil
        self.vSyncEnabled = true
        self.pauseOnBattery = true
        self.pauseOnFullscreen = true
        self.pauseOnLowBattery = true
        self.lowBatteryThreshold = 20
        self.pauseOnScreenSharing = false
        self.pauseOnHighLoad = true
        self.pauseOnLostFocus = false
        self.pauseOnLidClosed = true
        self.pauseBeforeSleep = true
        self.pauseOnOcclusion = false
        self.displayTopology = .independent
        self.colorSpace = .p3
        self.themeMode = .auto
        self.thumbnailSize = .medium
        self.animationsEnabled = true
        self.launchAtLogin = false
        self.menuBarEnabled = true
        self.libraryPath = NSHomeDirectory() + "/Pictures/PlumWallPaper"
        self.wallpaperOpacity = 100
    }

    var appRules: [AppRule] {
        get {
            guard let json = appRulesJSON, let data = json.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([AppRule].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                appRulesJSON = String(data: data, encoding: .utf8)
            }
        }
    }
}
