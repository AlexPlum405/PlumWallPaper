// Sources/Storage/Models/ShaderPreset.swift
import Foundation
import SwiftData

@Model
final class ShaderPreset {
    var id: UUID
    var name: String
    var passesJSON: String
    var isBuiltIn: Bool
    var createdAt: Date

    @Relationship
    var wallpaper: Wallpaper?

    init(id: UUID = UUID(), name: String, passesJSON: String = "[]",
         isBuiltIn: Bool = false, createdAt: Date = Date()) {
        self.id = id; self.name = name; self.passesJSON = passesJSON
        self.isBuiltIn = isBuiltIn; self.createdAt = createdAt
    }

    var passes: [ShaderPassConfig] {
        get {
            guard let data = passesJSON.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([ShaderPassConfig].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                passesJSON = String(data: data, encoding: .utf8) ?? "[]"
            }
        }
    }
}
