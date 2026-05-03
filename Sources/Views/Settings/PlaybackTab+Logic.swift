import SwiftUI

extension PlaybackTab {
    // MARK: - 业务逻辑

    func setLoopMode(_ mode: LoopMode) {
        viewModel.settings?.loopMode = mode
        viewModel.save()
    }

    func setPlaybackRate(_ rate: Double) {
        viewModel.settings?.playbackRate = rate
        viewModel.save()
    }

    func setRandomStartPosition(_ enabled: Bool) {
        viewModel.settings?.randomStartPosition = enabled
        viewModel.save()
    }

    func setGlobalVolume(_ volume: Int) {
        viewModel.setGlobalVolume(volume)
    }

    func setDefaultMuted(_ enabled: Bool) {
        viewModel.settings?.defaultMuted = enabled
        viewModel.save()
    }

    func setPreviewOnlyAudio(_ enabled: Bool) {
        viewModel.settings?.previewOnlyAudio = enabled
        viewModel.save()
    }

    func setAudioDuckingEnabled(_ enabled: Bool) {
        viewModel.settings?.audioDuckingEnabled = enabled
        viewModel.save()
    }

    func setAudioScreenId(_ id: String) {
        viewModel.settings?.audioScreenId = id
        viewModel.save()
    }
}
