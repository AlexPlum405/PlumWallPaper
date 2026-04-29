// Sources/Storage/Models/Tag.swift
import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var color: String
    var wallpapers: [Wallpaper]

    init(id: UUID = UUID(), name: String, color: String = "#E03E3E") {
        self.id = id; self.name = name; self.color = color; self.wallpapers = []
    }
}
