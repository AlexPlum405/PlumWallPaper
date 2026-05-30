import SwiftUI

extension WallpaperDetailView {
    // MARK: - 预设操作
    func applyPreset(_ preset: BuiltInPreset) {
        studio.applyPreset(preset)
    }

    func resetFilters() {
        studio.resetFilters()
    }
}
