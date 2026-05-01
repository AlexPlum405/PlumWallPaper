import SwiftUI
import AppKit

// MARK: - 颗粒纹理磁贴生成器
private enum GrainTextureTile {
    static let image: NSImage = {
        let w = 128
        let h = 128
        guard
            let rep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: w,
                pixelsHigh: h,
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            ),
            let data = rep.bitmapData
        else {
            return NSImage(size: NSSize(width: 1, height: 1))
        }
        var state: UInt64 = 0x9E37_79B9_7F4A_7C15
        for y in 0..<h {
            for x in 0..<w {
                state = state &* 6_364_136_223_846_793_005 &+ 1
                let u = UInt32(truncatingIfNeeded: state >> 33)
                let v = UInt8(clamping: 55 + Int(u % 146))
                let o = (y * w + x) * 4
                data[o] = v
                data[o + 1] = v
                data[o + 2] = v
                data[o + 3] = 255
            }
        }
        let img = NSImage(size: NSSize(width: w, height: h))
        img.addRepresentation(rep)
        return img
    }()
}

// MARK: - 全局颗粒材质覆盖层
struct GrainTextureOverlay: View {
    var opacity: Double
    
    init(opacity: Double = 0.35) {
        self.opacity = opacity
    }

    var body: some View {
        Image(nsImage: GrainTextureTile.image)
            .resizable(resizingMode: .tile)
            .blendMode(.overlay)
            .opacity(opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
    }
}
