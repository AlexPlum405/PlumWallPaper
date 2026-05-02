// Sources/OnlineModels/RemoteWallpaper.swift
import Foundation

/// 在线静态壁纸模型（从 Wallhaven/4K Wallpapers 获取）
struct RemoteWallpaper: Codable, Identifiable, Hashable {
    let id: String
    let url: String
    let shortURL: String?
    let thumbURL: URL?
    let fullImageURL: URL?
    let resolution: String
    let dimensionX: Int
    let dimensionY: Int
    let fileSize: Int64
    let category: String        // "general", "anime", "people"
    let purity: String          // "sfw", "sketchy", "nsfw"
    let views: Int
    let favorites: Int
    let uploadedAt: Date
    let tags: [APITag]?
    let colors: [String]?

    enum CodingKeys: String, CodingKey {
        case id, url, resolution, category, purity, views, favorites, colors, tags
        case shortURL = "short_url"
        case thumbURL = "thumbs"
        case fullImageURL = "path"
        case dimensionX = "dimension_x"
        case dimensionY = "dimension_y"
        case fileSize = "file_size"
        case uploadedAt = "created_at"
    }

    // 普通初始化器
    init(
        id: String,
        url: String,
        shortURL: String? = nil,
        thumbURL: URL? = nil,
        fullImageURL: URL? = nil,
        resolution: String,
        dimensionX: Int,
        dimensionY: Int,
        fileSize: Int64,
        category: String,
        purity: String,
        views: Int,
        favorites: Int,
        uploadedAt: Date,
        tags: [APITag]? = nil,
        colors: [String]? = nil
    ) {
        self.id = id
        self.url = url
        self.shortURL = shortURL
        self.thumbURL = thumbURL
        self.fullImageURL = fullImageURL
        self.resolution = resolution
        self.dimensionX = dimensionX
        self.dimensionY = dimensionY
        self.fileSize = fileSize
        self.category = category
        self.purity = purity
        self.views = views
        self.favorites = favorites
        self.uploadedAt = uploadedAt
        self.tags = tags
        self.colors = colors
    }

    // 自定义解码
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        url = try container.decode(String.self, forKey: .url)
        shortURL = try container.decodeIfPresent(String.self, forKey: .shortURL)
        fullImageURL = try container.decodeIfPresent(URL.self, forKey: .fullImageURL)
        resolution = try container.decode(String.self, forKey: .resolution)
        dimensionX = try container.decode(Int.self, forKey: .dimensionX)
        dimensionY = try container.decode(Int.self, forKey: .dimensionY)
        fileSize = try container.decode(Int64.self, forKey: .fileSize)
        category = try container.decode(String.self, forKey: .category)
        purity = try container.decode(String.self, forKey: .purity)
        views = try container.decode(Int.self, forKey: .views)
        favorites = try container.decode(Int.self, forKey: .favorites)
        uploadedAt = try container.decode(Date.self, forKey: .uploadedAt)
        tags = try container.decodeIfPresent([APITag].self, forKey: .tags)
        colors = try container.decodeIfPresent([String].self, forKey: .colors)

        // thumbs 是一个字典，包含 large, original, small
        if let thumbsDict = try? container.decode([String: String].self, forKey: .thumbURL),
           let largeThumb = thumbsDict["large"] ?? thumbsDict["original"] ?? thumbsDict["small"],
           let thumbURL = URL(string: largeThumb) {
            self.thumbURL = thumbURL
        } else {
            self.thumbURL = nil
        }
    }

    // 自定义编码
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(shortURL, forKey: .shortURL)
        try container.encodeIfPresent(fullImageURL, forKey: .fullImageURL)
        try container.encode(resolution, forKey: .resolution)
        try container.encode(dimensionX, forKey: .dimensionX)
        try container.encode(dimensionY, forKey: .dimensionY)
        try container.encode(fileSize, forKey: .fileSize)
        try container.encode(category, forKey: .category)
        try container.encode(purity, forKey: .purity)
        try container.encode(views, forKey: .views)
        try container.encode(favorites, forKey: .favorites)
        try container.encode(uploadedAt, forKey: .uploadedAt)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(colors, forKey: .colors)

        // 编码 thumbURL 为字符串
        if let thumbURL = thumbURL {
            try container.encode(thumbURL.absoluteString, forKey: .thumbURL)
        }
    }
}

/// API 标签
struct APITag: Codable, Hashable {
    let id: Int
    let name: String
    let alias: String?
    let categoryID: Int
    let category: String
    let purity: String

    enum CodingKeys: String, CodingKey {
        case id, name, alias, category, purity
        case categoryID = "category_id"
    }
}

/// Wallhaven API 响应
struct WallhavenResponse: Codable {
    let data: [RemoteWallpaper]
    let meta: Meta

    struct Meta: Codable {
        let currentPage: Int
        let lastPage: Int
        let perPage: Int
        let total: Int

        enum CodingKeys: String, CodingKey {
            case total
            case currentPage = "current_page"
            case lastPage = "last_page"
            case perPage = "per_page"
        }
    }
}
