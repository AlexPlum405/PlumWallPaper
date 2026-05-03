import SwiftUI

extension DisplayTab {
    // MARK: - 业务逻辑

    func setDisplayTopology(_ topology: DisplayTopology) {
        viewModel.setDisplayTopology(topology)
    }

    func setColorSpace(_ option: ColorSpaceOption) {
        viewModel.setColorSpace(option)
    }

    func setThemeMode(_ mode: ThemeMode) {
        viewModel.setTheme(mode)
    }

    func setThumbnailSize(_ size: ThumbnailSize) {
        viewModel.setThumbnailSize(size)
    }

    func setAnimationsEnabled(_ enabled: Bool) {
        viewModel.setAnimationsEnabled(enabled)
    }

    func setWallpaperOpacity(_ opacity: Int) {
        viewModel.setWallpaperOpacity(opacity)
    }

    func setFilmGrainEnabled(_ enabled: Bool) {
        viewModel.settings?.pauseOnOcclusion = enabled
        viewModel.save()
    }
}
