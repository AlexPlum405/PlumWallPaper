import Foundation

@MainActor
final class AudioDuckingMonitor {
    static let shared = AudioDuckingMonitor()

    private var timer: Timer?
    private var isOtherAppPlaying = false
    private var preDuckingMuteStates: [String: Bool] = [:]

    private typealias MRGetNowPlayingInfoFn = @convention(c) (DispatchQueue, @escaping ([String: Any]?) -> Void) -> Void
    private let getNowPlayingInfo: MRGetNowPlayingInfoFn?

    private init() {
        let handle = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY)
        if let handle, let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") {
            getNowPlayingInfo = unsafeBitCast(sym, to: MRGetNowPlayingInfoFn.self)
        } else {
            getNowPlayingInfo = nil
            NSLog("[AudioDucking] MediaRemote.framework not available, ducking disabled")
        }
    }

    func startMonitoring(enabled: Bool) {
        timer?.invalidate()
        timer = nil
        guard enabled, getNowPlayingInfo != nil else {
            if isOtherAppPlaying { restoreAudio() }
            isOtherAppPlaying = false
            return
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkNowPlaying() }
        }
    }

    func stopMonitoring() {
        startMonitoring(enabled: false)
    }

    private func checkNowPlaying() {
        getNowPlayingInfo?(DispatchQueue.main) { [weak self] info in
            guard let self else { return }
            let rate = info?["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0
            let isPlaying = rate > 0

            if isPlaying && !self.isOtherAppPlaying {
                self.isOtherAppPlaying = true
                self.muteAudio()
            } else if !isPlaying && self.isOtherAppPlaying {
                self.isOtherAppPlaying = false
                self.restoreAudio()
            }
        }
    }

    private func muteAudio() {
        preDuckingMuteStates.removeAll()
        // 通过 RenderPipeline 获取各屏幕渲染器的静音状态并静音
        for (id, isMuted) in RenderPipeline.shared.getAudioMuteStates() {
            preDuckingMuteStates[id] = isMuted
        }
        RenderPipeline.shared.setMuted(true)
    }

    private func restoreAudio() {
        // 恢复每个屏幕渲染器的原始静音状态
        for (id, wasMuted) in preDuckingMuteStates {
            RenderPipeline.shared.setMuted(wasMuted, screenId: id)
        }
        preDuckingMuteStates.removeAll()
    }
}
