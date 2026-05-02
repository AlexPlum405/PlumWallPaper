// Sources/Storage/Models/Settings.swift
import Foundation
import SwiftData

@Model
final class Settings {
    var slideshowEnabled: Bool = false
    var slideshowInterval: Double = 1800
    var slideshowOrder: SlideshowOrder = SlideshowOrder.sequential
    var slideshowSource: SlideshowSource = SlideshowSource.all
    var slideshowTagId: String?
    var transitionEffect: TransitionEffect = TransitionEffect.fade
    var loopMode: LoopMode = LoopMode.loop
    var playbackRate: Double = 1.0
    var randomStartPosition: Bool = false
    var globalVolume: Int = 100
    var defaultMuted: Bool = false
    var previewOnlyAudio: Bool = false
    var audioDuckingEnabled: Bool = true
    var audioScreenId: String?
    var fpsLimit: Int?
    var vSyncEnabled: Bool = true
    var pauseOnBattery: Bool = true
    var pauseOnFullscreen: Bool = true
    var pauseOnLowBattery: Bool = true
    var lowBatteryThreshold: Int = 20
    var pauseOnScreenSharing: Bool = false
    var pauseOnHighLoad: Bool = true
    var pauseOnLostFocus: Bool = false
    var pauseOnLidClosed: Bool = true
    var pauseBeforeSleep: Bool = true
    var pauseOnOcclusion: Bool = false
    var displayTopology: DisplayTopology = DisplayTopology.independent
    var colorSpace: ColorSpaceOption = ColorSpaceOption.p3
    var screenOrder: [String]?
    var themeMode: ThemeMode = ThemeMode.auto
    var thumbnailSize: ThumbnailSize = ThumbnailSize.medium
    var animationsEnabled: Bool = true
    var launchAtLogin: Bool = false
    var menuBarEnabled: Bool = true
    var libraryPath: String = NSHomeDirectory() + "/Pictures/PlumWallPaper"
    var wallpaperOpacity: Int = 100
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
