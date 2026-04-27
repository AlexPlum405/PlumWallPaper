import Foundation
import AVFoundation
import CoreImage
import AppKit

/// 滤镜引擎
final class FilterEngine {
    static let shared = FilterEngine()
    private init() {}

    /// 为视频生成 AVVideoComposition
    func videoComposition(for asset: AVAsset, preset: FilterPreset) -> AVVideoComposition {
        return AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
            let output = self.compositeCIImage(request.sourceImage, preset: preset)
            request.finish(with: output, context: nil)
        })
    }

    /// 为 HEIC 应用滤镜并返回处理后的图像
    func applyToImage(at url: URL, preset: FilterPreset) -> NSImage? {
        guard let ciImage = CIImage(contentsOf: url) else { return nil }
        let output = compositeCIImage(ciImage, preset: preset)
        let context = CIContext()
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: output.extent.width, height: output.extent.height))
    }

    /// 核心：从 FilterPreset 构建 CIImage 处理链
    func compositeCIImage(_ input: CIImage, preset: FilterPreset) -> CIImage {
        var output = input

        // 1. 曝光度
        if preset.exposure != 100 {
            let ev = (preset.exposure - 100) / 50.0
            if let filter = CIFilter(name: "CIExposureAdjust") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(ev, forKey: kCIInputEVKey)
                if let result = filter.outputImage {
                    output = result
                }
            }
        }

        // 2. 对比度 + 饱和度 + 黑白（合并到 CIColorControls）
        let contrast = preset.contrast / 100.0
        let saturation = (preset.saturation / 100.0) * (1.0 - preset.grayscale / 100.0)
        if let filter = CIFilter(name: "CIColorControls") {
            filter.setValue(output, forKey: kCIInputImageKey)
            filter.setValue(contrast, forKey: kCIInputContrastKey)
            filter.setValue(saturation, forKey: kCIInputSaturationKey)
            if let result = filter.outputImage {
                output = result
            }
        }

        // 3. 色调
        if preset.hue != 0 {
            let angle = preset.hue * .pi / 180.0
            if let filter = CIFilter(name: "CIHueAdjust") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(angle, forKey: "inputAngle")
                if let result = filter.outputImage {
                    output = result
                }
            }
        }

        // 4. 模糊
        if preset.blur > 0 {
            if let filter = CIFilter(name: "CIGaussianBlur") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(preset.blur, forKey: kCIInputRadiusKey)
                if let result = filter.outputImage {
                    output = result.clampedToExtent().cropped(to: input.extent)
                }
            }
        }

        // 5. 暗角
        if preset.vignette > 0 {
            let intensity = preset.vignette / 100.0
            if let filter = CIFilter(name: "CIVignette") {
                filter.setValue(output, forKey: kCIInputImageKey)
                filter.setValue(intensity, forKey: kCIInputIntensityKey)
                if let result = filter.outputImage {
                    output = result
                }
            }
        }

        // 6. 颗粒感
        if preset.grain > 0 {
            let alpha = preset.grain / 100.0
            if let noiseFilter = CIFilter(name: "CIRandomGenerator"),
               let noiseImage = noiseFilter.outputImage?.cropped(to: input.extent) {
                if let blendFilter = CIFilter(name: "CISourceOverCompositing") {
                    let grainImage = noiseImage.applyingFilter("CIColorMatrix", parameters: [
                        "inputRVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                        "inputGVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                        "inputBVector": CIVector(x: 0, y: 0, z: 0, w: 0),
                        "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(alpha)),
                        "inputBiasVector": CIVector(x: 0, y: 0, z: 0, w: 0)
                    ])
                    blendFilter.setValue(grainImage, forKey: kCIInputImageKey)
                    blendFilter.setValue(output, forKey: kCIInputBackgroundImageKey)
                    if let result = blendFilter.outputImage {
                        output = result
                    }
                }
            }
        }

        // 7. 反转
        if preset.invert > 50 {
            if let filter = CIFilter(name: "CIColorInvert") {
                filter.setValue(output, forKey: kCIInputImageKey)
                if let result = filter.outputImage {
                    output = result
                }
            }
        }

        return output
    }
}
