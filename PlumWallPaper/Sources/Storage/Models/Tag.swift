//
//  Tag.swift
//  PlumWallPaper
//
//  Created on 2026-04-28.
//

import Foundation
import SwiftData

/// 标签数据模型
@Model
final class Tag {
    /// 唯一标识符
    var id: UUID

    /// 标签名称
    var name: String

    /// 标签颜色（HEX）
    var color: String?

    /// 关联的壁纸
    @Relationship(deleteRule: .nullify, inverse: \Wallpaper.tags)
    var wallpapers: [Wallpaper]

    init(
        id: UUID = UUID(),
        name: String,
        color: String? = nil,
        wallpapers: [Wallpaper] = []
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.wallpapers = wallpapers
    }
}

// MARK: - Predefined Tags
extension Tag {
    static let nature = Tag(name: "自然", color: "#2ECC71")
    static let city = Tag(name: "城市", color: "#3498DB")
    static let anime = Tag(name: "动漫", color: "#E03E3E")
    static let sciFi = Tag(name: "科幻", color: "#9B59B6")
}
