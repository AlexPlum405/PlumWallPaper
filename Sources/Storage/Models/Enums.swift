// Sources/Storage/Models/Enums.swift
import Foundation

enum WallpaperType: String, Codable {
    case video, heic, image
}

enum LoopMode: String, Codable {
    case loop, once
}

enum SlideshowSource: String, Codable {
    case all, favorites, tag
}

enum SlideshowOrder: String, Codable {
    case sequential, random, favoritesFirst
}

enum TransitionEffect: String, Codable {
    case fade, kenBurns, none
}

enum DisplayTopology: String, Codable {
    case independent, mirror, panorama
}

enum ColorSpaceOption: String, Codable {
    case p3, srgb, adobeRGB
}

enum ThemeMode: String, Codable, CaseIterable, Identifiable {
    case auto, light, dark
    var id: String { rawValue }
}

enum ThumbnailSize: String, Codable {
    case small, medium, large
}

enum RuleAction: String, Codable {
    case pause, mute, limitFPS30, limitFPS15, none
}

struct ShaderPassConfig: Codable, Identifiable {
    var id: UUID
    var type: ShaderPassType
    var name: String
    var enabled: Bool
    var parameters: [String: ShaderParameterValue]
}

enum ShaderPassType: String, Codable {
    case filter, particle, postprocess
}

enum ShaderParameterValue: Codable {
    case float(Float)
    case vec2(SIMD2<Float>)
    case vec4(SIMD4<Float>)
    case bool(Bool)
    case int(Int)
}

struct AppRule: Codable, Identifiable {
    let id: String
    let bundleIdentifier: String
    let appName: String
    let action: RuleAction
    var enabled: Bool
    var triggerCount: Int
    var lastTriggered: Date?

    init(id: String, bundleIdentifier: String, appName: String, action: RuleAction, enabled: Bool = true) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.action = action
        self.enabled = enabled
        self.triggerCount = 0
        self.lastTriggered = nil
    }
}
