import SwiftUI

extension WallpaperDetailView {
    // MARK: - 预设操作
    func applyPreset(_ preset: BuiltInPreset) {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentPresetName = preset.name
            exposure = preset.exposure; contrast = preset.contrast
            saturation = preset.saturation; hue = preset.hue
            blur = preset.blur; grain = preset.grain
            vignette = preset.vignette; grayscale = preset.grayscale
            invert = preset.invert
        }
    }

    func resetFilters() {
        applyPreset(.original)
    }
}
