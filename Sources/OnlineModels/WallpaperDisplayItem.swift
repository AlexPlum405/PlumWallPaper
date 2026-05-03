// Sources/OnlineModels/WallpaperDisplayItem.swift
import Foundation

/// UI 层统一展示模型（在线 + 本地）
enum WallpaperDisplayItem: Identifiable {
    case remote(RemoteWallpaper)
    case media(MediaItem)
    case local(Wallpaper)

    var id: String {
        switch self {
        case .remote(let w): return "remote-\(w.id)"
        case .media(let m): return "media-\(m.id)"
        case .local(let w): return "local-\(w.id.uuidString)"
        }
    }

    var title: String {
        switch self {
        case .remote(let w): return w.tags?.first?.name ?? "Wallpaper \(w.id)"
        case .media(let m): return m.title
        case .local(let w): return w.name
        }
    }

    var thumbnailURL: URL? {
        switch self {
        case .remote(let w): return w.thumbURL
        case .media(let m): return m.thumbnailURL
        case .local(let w):
            guard let thumbnailPath = w.thumbnailPath else { return nil }
            if let url = URL(string: thumbnailPath), url.scheme != nil {
                return url
            }
            return URL(fileURLWithPath: thumbnailPath)
        }
    }

    var resolution: String {
        switch self {
        case .remote(let w): return w.resolution
        case .media(let m): return m.resolutionLabel
        case .local(let w): return w.resolution ?? "Unknown"
        }
    }

    var type: WallpaperType {
        switch self {
        case .remote: return .image
        case .media: return .video
        case .local(let w): return w.type
        }
    }

    var isLocal: Bool {
        if case .local = self { return true }
        return false
    }

    var canApplyDirectly: Bool {
        isLocal
    }

    var views: Int? {
        switch self {
        case .remote(let w): return w.views
        case .media(let m): return m.viewCount ?? m.subscriptionCount
        case .local: return nil
        }
    }

    var favorites: Int? {
        switch self {
        case .remote(let w): return w.favorites
        case .media(let m): return m.favoriteCount
        case .local: return nil
        }
    }
}
