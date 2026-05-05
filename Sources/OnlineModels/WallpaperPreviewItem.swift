import Foundation

/// Pure value model for wallpaper preview UI.
/// SwiftData `Wallpaper` should be created only at persistence boundaries.
struct WallpaperPreviewItem: Identifiable, Hashable {
    let id: String
    let title: String
    let contentURL: URL?
    let thumbnailURL: URL?
    let type: WallpaperType
    let resolution: String?
    let fileSize: Int64
    let duration: Double?
    let frameRate: Double?
    let hasAudio: Bool
    let isFavorite: Bool
    let source: WallpaperSource
    let remoteId: String?
    let remoteSource: RemoteSourceType?
    let downloadQuality: String?
    let metadata: RemoteMetadata?

    var filePath: String {
        contentURL?.absoluteString ?? ""
    }

    var thumbnailPath: String? {
        thumbnailURL?.absoluteString
    }

    static func == (lhs: WallpaperPreviewItem, rhs: WallpaperPreviewItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    init(
        id: String,
        title: String,
        contentURL: URL?,
        thumbnailURL: URL?,
        type: WallpaperType,
        resolution: String? = nil,
        fileSize: Int64 = 0,
        duration: Double? = nil,
        frameRate: Double? = nil,
        hasAudio: Bool = false,
        isFavorite: Bool = false,
        source: WallpaperSource = .online,
        remoteId: String? = nil,
        remoteSource: RemoteSourceType? = nil,
        downloadQuality: String? = nil,
        metadata: RemoteMetadata? = nil
    ) {
        self.id = id
        self.title = title
        self.contentURL = contentURL
        self.thumbnailURL = thumbnailURL
        self.type = type
        self.resolution = resolution
        self.fileSize = fileSize
        self.duration = duration
        self.frameRate = frameRate
        self.hasAudio = hasAudio
        self.isFavorite = isFavorite
        self.source = source
        self.remoteId = remoteId
        self.remoteSource = remoteSource
        self.downloadQuality = downloadQuality
        self.metadata = metadata
    }

    init(wallpaper: Wallpaper) {
        self.init(
            id: wallpaper.remoteId ?? wallpaper.id.uuidString,
            title: wallpaper.name,
            contentURL: Self.url(from: wallpaper.filePath),
            thumbnailURL: wallpaper.thumbnailPath.flatMap(Self.url(from:)),
            type: wallpaper.type,
            resolution: wallpaper.resolution,
            fileSize: wallpaper.fileSize,
            duration: wallpaper.duration,
            frameRate: wallpaper.frameRate,
            hasAudio: wallpaper.hasAudio,
            isFavorite: wallpaper.isFavorite,
            source: wallpaper.source,
            remoteId: wallpaper.remoteId,
            remoteSource: wallpaper.remoteSource,
            downloadQuality: wallpaper.downloadQuality,
            metadata: wallpaper.remoteMetadata
        )
    }

    init(remote: RemoteWallpaper) {
        self.init(
            id: remote.id,
            title: remote.id,
            contentURL: remote.fullImageURL,
            thumbnailURL: remote.thumbURL,
            type: .image,
            resolution: remote.resolution,
            fileSize: remote.fileSize,
            source: .online,
            remoteId: remote.id,
            remoteSource: Self.remoteSource(fromRemoteId: remote.id),
            metadata: RemoteMetadata(
                author: nil,
                views: remote.views,
                favorites: remote.favorites,
                uploadDate: remote.uploadedAt,
                originalURL: remote.url
            )
        )
    }

    init(media: MediaItem) {
        let remoteSource = Self.remoteSource(fromMediaSourceName: media.sourceName)
        let contentURL = media.fullVideoURL ?? media.previewVideoURL

        self.init(
            id: media.id,
            title: media.title,
            contentURL: contentURL,
            thumbnailURL: media.thumbnailURL,
            type: .video,
            resolution: media.exactResolution ?? media.resolutionLabel,
            fileSize: media.fileSize ?? 0,
            duration: media.durationSeconds,
            hasAudio: media.hasAudioTrack ?? false,
            source: .online,
            remoteId: media.id,
            remoteSource: remoteSource,
            downloadQuality: media.fullVideoURL?.absoluteString,
            metadata: RemoteMetadata(
                author: media.authorName,
                views: media.viewCount,
                favorites: media.favoriteCount,
                uploadDate: media.createdAt,
                originalURL: media.pageURL.absoluteString
            )
        )
    }

    func makeWallpaper() -> Wallpaper {
        Wallpaper(
            name: title,
            filePath: filePath,
            type: type,
            resolution: resolution,
            fileSize: fileSize,
            duration: duration,
            frameRate: frameRate,
            hasAudio: hasAudio,
            thumbnailPath: thumbnailPath,
            isFavorite: isFavorite,
            source: source,
            remoteId: remoteId,
            remoteSource: remoteSource,
            downloadQuality: downloadQuality,
            remoteMetadata: metadata
        )
    }

    private static func url(from path: String) -> URL? {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil { return url }
        return URL(fileURLWithPath: trimmed)
    }

    private static func remoteSource(fromRemoteId id: String) -> RemoteSourceType {
        if id.hasPrefix("pexels_") { return .pexels }
        if id.hasPrefix("unsplash_") { return .unsplash }
        if id.hasPrefix("pixabay_") { return .pixabay }
        if id.hasPrefix("bing_") { return .bingDaily }
        return .wallhaven
    }

    private static func remoteSource(fromMediaSourceName name: String) -> RemoteSourceType {
        switch name.lowercased() {
        case "motionbg": return .motionBG
        case "steam workshop": return .steamWorkshop
        case "pexels": return .pexels
        case "pixabay": return .pixabay
        case "desktophut": return .desktopHut
        default: return .motionBG
        }
    }
}
