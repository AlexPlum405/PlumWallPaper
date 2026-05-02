// Sources/Network/WorkshopSourceManager.swift
import Foundation
import Combine
import SwiftUI

// MARK: - Wallpaper Engine Workshop Source Manager

/// Manages Wallpaper Engine Steam Workshop data source switching
/// Supports multiple wallpaper sources: MotionBG (current) / Wallpaper Engine Workshop
@MainActor
class WorkshopSourceManager: ObservableObject {
    static let shared = WorkshopSourceManager()

    // MARK: - Source Type

    enum SourceType: String, CaseIterable {
        case motionBG = "motionbg"
        case wallpaperEngine = "wallpaper_engine"

        var displayName: String {
            switch self {
            case .motionBG: return "MotionBG"
            case .wallpaperEngine: return "Wallpaper Engine"
            }
        }

        var subtitle: String {
            switch self {
            case .motionBG: return "Online Video Wallpapers"
            case .wallpaperEngine: return "Steam Workshop"
            }
        }

        var icon: String {
            switch self {
            case .motionBG: return "play.rectangle.fill"
            case .wallpaperEngine: return "gearshape.fill"
            }
        }

        var supportsSearch: Bool { true }
        var supportsCategories: Bool { true }
        var requiresSteamAuth: Bool {
            switch self {
            case .motionBG: return false
            case .wallpaperEngine: return false
            }
        }
    }

    // MARK: - Workshop Type Filter

    enum WorkshopTypeFilter: String, CaseIterable, Identifiable {
        case all = "all"
        case scene = "Scene"
        case video = "Video"
        case web = "Web"
        case application = "Application"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .all: return "All Types"
            case .scene: return "Scene"
            case .video: return "Video"
            case .web: return "Web"
            case .application: return "Application"
            }
        }

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .scene: return "cube.fill"
            case .video: return "film.fill"
            case .web: return "safari.fill"
            case .application: return "app.fill"
            }
        }
    }

    // MARK: - Workshop Content Level

    enum WorkshopContentLevel: String, CaseIterable, Identifiable {
        case everyone = "Everyone"
        case questionable = "Questionable"
        case mature = "Mature"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .everyone: return "Safe"
            case .questionable: return "Questionable"
            case .mature: return "NSFW"
            }
        }
    }

    // MARK: - Workshop Tags

    struct WorkshopTag: Identifiable, Hashable {
        let id: String
        let name: String
        let icon: String

        static let allTags: [WorkshopTag] = [
            WorkshopTag(id: "abstract", name: "Abstract", icon: "scribble"),
            WorkshopTag(id: "animal", name: "Animal", icon: "pawprint.fill"),
            WorkshopTag(id: "anime", name: "Anime", icon: "sparkles"),
            WorkshopTag(id: "cartoon", name: "Cartoon", icon: "face.smiling"),
            WorkshopTag(id: "cgi", name: "CGI", icon: "cpu.fill"),
            WorkshopTag(id: "cyberpunk", name: "Cyberpunk", icon: "bolt.fill"),
            WorkshopTag(id: "fantasy", name: "Fantasy", icon: "wand.and.stars"),
            WorkshopTag(id: "game", name: "Game", icon: "gamecontroller.fill"),
            WorkshopTag(id: "landscape", name: "Landscape", icon: "photo.fill"),
            WorkshopTag(id: "music", name: "Music", icon: "music.note"),
            WorkshopTag(id: "nature", name: "Nature", icon: "leaf.fill"),
            WorkshopTag(id: "scifi", name: "Sci-Fi", icon: "bolt.fill"),
        ]
    }

    var availableTags: [WorkshopTag] {
        WorkshopTag.allTags
    }

    // MARK: - Workshop Resolution

    struct WorkshopResolution: Identifiable, Hashable {
        let id: String
        let display: String
        let tagValue: String

        static let all: [WorkshopResolution] = [
            WorkshopResolution(id: "3840x2160", display: "3840 × 2160 (4K UHD)", tagValue: "3840 x 2160"),
            WorkshopResolution(id: "2560x1440", display: "2560 × 1440 (2K QHD)", tagValue: "2560 x 1440"),
            WorkshopResolution(id: "1920x1080", display: "1920 × 1080 (FHD)", tagValue: "1920 x 1080"),
        ]
    }

    var availableResolutions: [WorkshopResolution] {
        WorkshopResolution.all
    }

    // MARK: - SteamCMD Credentials

    struct SteamCredentials: Codable {
        let username: String
        let password: String
        let guardCode: String?
    }

    private let steamCredentialsKey = "workshop_steam_credentials"

    var steamCredentials: SteamCredentials? {
        get {
            guard let data = UserDefaults.standard.data(forKey: steamCredentialsKey),
                  let creds = try? JSONDecoder().decode(SteamCredentials.self, from: data) else {
                return nil
            }
            return creds
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: steamCredentialsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: steamCredentialsKey)
            }
            objectWillChange.send()
        }
    }

    var isSteamCMDLoggedIn: Bool {
        steamCredentials != nil
    }

    func setSteamCredentials(username: String, password: String, guardCode: String? = nil) {
        steamCredentials = SteamCredentials(username: username, password: password, guardCode: guardCode)
    }

    func clearSteamCredentials() {
        steamCredentials = nil
    }

    // MARK: - Published State

    @Published private(set) var activeSource: SourceType
    @Published var lastSwitchMessage: String?

    // MARK: - Storage Keys

    private let selectedSourceKey = "workshop_selected_source"

    private init() {
        activeSource = .motionBG
        restoreState()
    }

    private func restoreState() {
        if let saved = UserDefaults.standard.string(forKey: selectedSourceKey),
           let source = SourceType(rawValue: saved) {
            activeSource = source
        }
    }

    // MARK: - Public API

    var isUsingWallpaperEngine: Bool {
        activeSource == .wallpaperEngine
    }

    var currentSourceSupportsSearch: Bool {
        activeSource.supportsSearch
    }

    var currentSourceSupportsCategories: Bool {
        activeSource.supportsCategories
    }

    func currentSource() -> SourceType {
        activeSource
    }

    func switchTo(_ source: SourceType) {
        guard activeSource != source else { return }

        let previousSource = activeSource
        activeSource = source

        UserDefaults.standard.set(source.rawValue, forKey: selectedSourceKey)

        lastSwitchMessage = "Switched to \(source.displayName) - \(source.subtitle)"

        NotificationCenter.default.post(name: .workshopSourceChanged, object: nil)

        print("[WorkshopSourceManager] Switched from \(previousSource.displayName) to \(source.displayName)")
    }

    func switchToNext() {
        let allSources = SourceType.allCases
        guard let currentIndex = allSources.firstIndex(of: activeSource) else { return }
        let nextIndex = (currentIndex + 1) % allSources.count
        switchTo(allSources[nextIndex])
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let workshopSourceChanged = Notification.Name("workshopSourceChanged")
}
