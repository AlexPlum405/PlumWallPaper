import SwiftUI

extension WallpaperDetailView {
    // MARK: - 预设操作
    func applyPreset(_ preset: BuiltInPreset) {
        NSLog("[WallpaperDetailView] 应用预设: \(preset.name)")
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
        withAnimation(.gallerySpring) {
            particleRate = 60
            particleLifetime = 3
            particleSize = 4
            particleGravity = 9.8
            particleTurbulence = 2
            particleSpin = 0
            particleThrust = 0
            particleAngle = 0
            particleSpread = 360
            particleColorStart = .white
            particleColorEnd = LiquidGlassColors.primaryPink
            particleStyle = "circle.fill"
        }
    }

    func openShaderEditor() {
        print("openShaderEditor called")
        isShowingShaderEditor = true
    }
}
