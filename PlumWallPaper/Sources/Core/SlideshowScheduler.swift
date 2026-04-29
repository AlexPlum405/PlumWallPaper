import Foundation
import SwiftData

@MainActor
final class SlideshowScheduler {
    static let shared = SlideshowScheduler()

    private var timer: Timer?
    private var playlistIds: [UUID] = []
    private var currentIndex: Int = 0
    private var isPaused = false
    private var isAutoSwitching = false
    private weak var modelContext: ModelContext?
    private var currentInterval: TimeInterval = 1800
    private var currentOrder: SlideshowOrder = .sequential

    var onSwitchWallpaper: ((Wallpaper) -> Void)?

    private init() {}

    func start(context: ModelContext, settings: Settings) {
        self.modelContext = context
        self.currentInterval = settings.slideshowInterval
        self.currentOrder = settings.slideshowOrder
        buildPlaylist(context: context, settings: settings)
        guard !playlistIds.isEmpty else { return }
        let currentIds = WallpaperEngine.shared.activeWallpaperIds
        if let firstActive = currentIds.first,
           let idx = playlistIds.firstIndex(of: firstActive) {
            currentIndex = idx
        } else {
            currentIndex = 0
        }
        startTimer(interval: currentInterval)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        playlistIds = []
        currentIndex = 0
        isPaused = false
    }

    func next() {
        guard !playlistIds.isEmpty else { return }
        guard let context = modelContext else { stop(); return }
        currentIndex = (currentIndex + 1) % playlistIds.count
        let currentlyShowing = WallpaperEngine.shared.activeWallpaperIds
        if playlistIds.count > 1 && currentlyShowing.contains(playlistIds[currentIndex]) {
            currentIndex = (currentIndex + 1) % playlistIds.count
        }
        let id = playlistIds[currentIndex]
        let descriptor = FetchDescriptor<Wallpaper>(predicate: #Predicate { $0.id == id })
        guard let wallpaper = try? context.fetch(descriptor).first else { return }
        isAutoSwitching = true
        onSwitchWallpaper?(wallpaper)
        isAutoSwitching = false
        resetTimer()
    }

    func prev() {
        guard !playlistIds.isEmpty else { return }
        guard let context = modelContext else { stop(); return }
        currentIndex = (currentIndex - 1 + playlistIds.count) % playlistIds.count
        let id = playlistIds[currentIndex]
        let descriptor = FetchDescriptor<Wallpaper>(predicate: #Predicate { $0.id == id })
        guard let wallpaper = try? context.fetch(descriptor).first else { return }
        isAutoSwitching = true
        onSwitchWallpaper?(wallpaper)
        isAutoSwitching = false
        resetTimer()
    }

    func pause() {
        isPaused = true
        timer?.fireDate = Date.distantFuture
    }

    func resume() {
        isPaused = false
        resetTimer()
    }

    func rebuildPlaylist() {
        guard let context = modelContext else { return }
        guard let settings = try? PreferencesStore(modelContext: context).fetchSettings() else { return }
        let oldId = playlistIds.indices.contains(currentIndex) ? playlistIds[currentIndex] : nil
        buildPlaylist(context: context, settings: settings)
        if let oldId, let idx = playlistIds.firstIndex(of: oldId) {
            currentIndex = idx
        } else {
            currentIndex = 0
        }
    }

    func updateInterval(_ interval: TimeInterval) {
        currentInterval = interval
        resetTimer()
    }

    func onWallpaperChanged(_ wallpaperId: UUID) {
        guard !isAutoSwitching else { return }
        if let index = playlistIds.firstIndex(of: wallpaperId) {
            currentIndex = index
        }
        resetTimer()
    }

    func getStatus() -> (current: Int, total: Int, nextIn: Int) {
        let nextIn: Int
        if let timer = timer, !isPaused {
            nextIn = max(0, Int(timer.fireDate.timeIntervalSinceNow))
        } else {
            nextIn = 0
        }
        return (current: currentIndex + 1, total: playlistIds.count, nextIn: nextIn)
    }

    // MARK: - Private

    private func buildPlaylist(context: ModelContext, settings: Settings) {
        let wallpapers: [Wallpaper]
        switch settings.slideshowSource {
        case .favorites:
            let descriptor = FetchDescriptor<Wallpaper>(predicate: #Predicate { $0.isFavorite == true })
            wallpapers = (try? context.fetch(descriptor)) ?? []
        case .tag:
            if let tagId = settings.slideshowTagId,
               let tagUUID = UUID(uuidString: tagId) {
                let tagDescriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.id == tagUUID })
                if let tag = try? context.fetch(tagDescriptor).first {
                    wallpapers = tag.wallpapers
                } else {
                    wallpapers = []
                }
            } else {
                wallpapers = []
            }
        case .all:
            let descriptor = FetchDescriptor<Wallpaper>()
            wallpapers = (try? context.fetch(descriptor)) ?? []
        }
        playlistIds = applySorting(wallpapers, order: settings.slideshowOrder).map(\.id)
    }

    private func applySorting(_ wallpapers: [Wallpaper], order: SlideshowOrder) -> [Wallpaper] {
        switch order {
        case .random:
            return wallpapers.shuffled()
        case .favoritesFirst:
            let favs = wallpapers.filter { $0.isFavorite }.sorted { $0.importDate < $1.importDate }
            let rest = wallpapers.filter { !$0.isFavorite }.sorted { $0.importDate < $1.importDate }
            return favs + rest
        case .sequential:
            return wallpapers.sorted { $0.importDate < $1.importDate }
        }
    }

    private func startTimer(interval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.next() }
        }
    }

    private func resetTimer() {
        guard let timer, !isPaused else { return }
        timer.fireDate = Date().addingTimeInterval(currentInterval)
    }
}
