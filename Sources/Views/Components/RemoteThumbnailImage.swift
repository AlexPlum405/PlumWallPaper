import AppKit
import SwiftUI

struct RemoteThumbnailImage: View {
    let urls: [URL]
    var contentMode: ContentMode = .fill

    @State private var phase: LoadPhase = .empty

    private enum LoadPhase {
        case empty
        case loading
        case success(NSImage)
        case failure
    }

    private var candidateURLs: [URL] {
        var seen = Set<String>()
        return urls.filter { url in
            seen.insert(url.absoluteString).inserted
        }
    }

    private var cacheKey: String {
        candidateURLs.map(\.absoluteString).joined(separator: "|")
    }

    var body: some View {
        Group {
            switch phase {
            case .success(let image):
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
            case .loading, .empty:
                loadingPlaceholder
            case .failure:
                fallbackPlaceholder
            }
        }
        .task(id: cacheKey) {
            await load()
        }
    }

    @MainActor
    private func load() async {
        guard !candidateURLs.isEmpty else {
            phase = .failure
            return
        }

        // 先检查内存缓存
        for url in candidateURLs {
            if let cached = RemoteThumbnailImageCache.shared.image(for: url) {
                phase = .success(cached)
                return
            }
        }

        // 再检查磁盘缓存
        for url in candidateURLs {
            if let diskCached = await RemoteThumbnailImageCache.shared.loadFromDisk(url: url) {
                phase = .success(diskCached)
                return
            }
        }

        phase = .loading

        // 最后从网络加载
        for url in candidateURLs {
            do {
                let image = try await Self.loadImage(from: url)
                RemoteThumbnailImageCache.shared.store(image, for: url)
                await RemoteThumbnailImageCache.shared.saveToDisk(image: image, url: url)
                phase = .success(image)
                return
            } catch {
                NSLog("[RemoteThumbnailImage] 缩略图加载失败: \(url.absoluteString), error: \(error.localizedDescription)")
            }
        }

        phase = .failure
    }

    private static func loadImage(from url: URL) async throws -> NSImage {
        if url.isFileURL {
            guard let image = NSImage(contentsOf: url), image.isValid else {
                throw URLError(.cannotDecodeContentData)
            }
            return image
        }

        var lastError: Error?

        for attempt in 0..<3 {
            do {
                let data = try await fetchImageData(from: url, forceRefresh: attempt > 0)
                guard let image = NSImage(data: data), image.isValid else {
                    throw URLError(.cannotDecodeContentData)
                }
                return image
            } catch {
                lastError = error
                if attempt < 2 {
                    let delay = UInt64(250_000_000 * UInt64(attempt + 1))
                    try? await Task.sleep(nanoseconds: delay)
                }
            }
        }

        throw lastError ?? URLError(.unknown)
    }

    private static func fetchImageData(from url: URL, forceRefresh: Bool) async throws -> Data {
        var request = URLRequest(url: url)
        request.cachePolicy = forceRefresh ? .reloadIgnoringLocalCacheData : .returnCacheDataElseLoad
        request.timeoutInterval = 20
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue(
            "image/jpeg,image/png,image/webp,image/*;q=0.8,*/*;q=0.5",
            forHTTPHeaderField: "Accept"
        )

        if let referer = referer(for: url) {
            request.setValue(referer, forHTTPHeaderField: "Referer")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private static func referer(for url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }
        if host.contains("pexels.com") { return "https://www.pexels.com/" }
        if host.contains("pixabay.com") { return "https://pixabay.com/" }
        if host.contains("unsplash.com") { return "https://unsplash.com/" }
        if host.contains("wallhaven.cc") || host.contains("w.wallhaven.cc") { return "https://wallhaven.cc/" }
        if host.contains("steam") { return "https://steamcommunity.com/" }
        if host.contains("desktophut.com") { return "https://www.desktophut.com/" }
        if host.contains("motionbgs.com") { return "https://motionbgs.com/" }
        return nil
    }

    private var loadingPlaceholder: some View {
        ZStack {
            Rectangle().fill(LiquidGlassColors.surfaceBackground)
            ProgressView()
                .controlSize(.small)
                .tint(LiquidGlassColors.textQuaternary)
        }
    }

    private var fallbackPlaceholder: some View {
        ZStack {
            Rectangle().fill(LiquidGlassColors.surfaceBackground)
            Image(systemName: "photo.on.rectangle.angled")
                .foregroundStyle(LiquidGlassColors.textQuaternary)
        }
    }
}

@MainActor
final class RemoteThumbnailImageCache {
    static let shared = RemoteThumbnailImageCache()

    private let cache = NSCache<NSURL, NSImage>()
    private let diskCacheDirectory: URL

    private init() {
        cache.countLimit = 240
        cache.totalCostLimit = 80 * 1024 * 1024

        // 初始化磁盘缓存目录
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheDirectory = caches.appendingPathComponent("PlumWallPaper/RemoteThumbnails", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
    }

    func image(for url: URL) -> NSImage? {
        cache.object(forKey: url as NSURL)
    }

    func store(_ image: NSImage, for url: URL) {
        let cost = max(1, Int(image.size.width * image.size.height * 4))
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }

    /// 从磁盘加载缓存
    func loadFromDisk(url: URL) async -> NSImage? {
        let cachePath = diskCachePath(for: url)
        guard FileManager.default.fileExists(atPath: cachePath.path) else {
            return nil
        }

        return await Task.detached(priority: .utility) {
            guard let image = NSImage(contentsOf: cachePath), image.isValid else {
                return nil
            }
            await MainActor.run {
                self.store(image, for: url)
            }
            return image
        }.value
    }

    /// 保存到磁盘
    func saveToDisk(image: NSImage, url: URL) async {
        let cachePath = diskCachePath(for: url)

        await Task.detached(priority: .utility) {
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.85]) else {
                return
            }

            try? jpegData.write(to: cachePath)
        }.value
    }

    /// 清理磁盘缓存
    func cleanDiskCache(olderThan days: Int = 30) {
        Task.detached(priority: .utility) {
            let fm = FileManager.default
            guard let files = try? fm.contentsOfDirectory(at: self.diskCacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) else {
                return
            }

            let cutoffDate = Date().addingTimeInterval(-Double(days * 24 * 3600))
            for file in files {
                guard let values = try? file.resourceValues(forKeys: [.contentModificationDateKey]),
                      let modDate = values.contentModificationDate,
                      modDate < cutoffDate else {
                    continue
                }
                try? fm.removeItem(at: file)
            }
        }
    }

    private func diskCachePath(for url: URL) -> URL {
        let hash = url.absoluteString.data(using: .utf8)!
            .base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        return diskCacheDirectory.appendingPathComponent(hash).appendingPathExtension("jpg")
    }
}
