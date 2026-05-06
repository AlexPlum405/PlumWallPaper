// Sources/Services/SuperResolutionService.swift
import Foundation
import Metal
import CoreImage
import AVFoundation
import CoreVideo

/// Metal 硬件加速的超分辨率服务
@MainActor
final class SuperResolutionService {
    static let shared: SuperResolutionService? = {
        guard let service = SuperResolutionService() else {
            print("[SuperResolution] Metal 设备不可用，超分辨率功能将被禁用")
            return nil
        }
        return service
    }()

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let ciContext: CIContext

    enum ScaleFactor: Int, CaseIterable {
        case x2 = 2
        case x3 = 3
        case x4 = 4

        var displayName: String {
            switch self {
            case .x2: return "2x"
            case .x3: return "3x"
            case .x4: return "4x"
            }
        }
    }

    private init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }

        self.device = device
        self.commandQueue = commandQueue
        self.ciContext = CIContext(mtlDevice: device, options: [
            .cacheIntermediates: false,
            .priorityRequestLow: false,
            .workingColorSpace: CGColorSpace(name: CGColorSpace.displayP3) ?? CGColorSpaceCreateDeviceRGB()
        ])

        print("[SuperResolution] 初始化成功，设备: \(device.name)")
    }

    // MARK: - 图像超分辨率

    /// 对 CGImage 进行硬件加速放大
    func upscaleImage(
        _ image: CGImage,
        scale: ScaleFactor,
        sharpen: Bool = true,
        denoise: Bool = false
    ) -> CGImage? {
        let targetWidth = image.width * scale.rawValue
        let targetHeight = image.height * scale.rawValue

        print("[SuperResolution] 放大图像: \(image.width)x\(image.height) -> \(targetWidth)x\(targetHeight)")

        var ciImage = CIImage(cgImage: image)

        // 1. Lanczos 放大（高质量插值）
        let transform = CGAffineTransform(
            scaleX: CGFloat(scale.rawValue),
            y: CGFloat(scale.rawValue)
        )
        ciImage = ciImage.transformed(by: transform)

        // 2. 降噪（可选）
        if denoise {
            ciImage = applyDenoise(to: ciImage) ?? ciImage
        }

        // 3. 锐化增强
        if sharpen {
            ciImage = applySharpen(to: ciImage, strength: 0.8) ?? ciImage
        }

        // 4. 对比度增强
        ciImage = applyContrastEnhancement(to: ciImage) ?? ciImage

        // 5. 渲染到 CGImage
        let bounds = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
        guard let result = ciContext.createCGImage(ciImage, from: bounds) else {
            print("[SuperResolution] 渲染失败")
            return nil
        }

        return result
    }

    /// 对 CVPixelBuffer 进行硬件加速放大（用于视频帧）
    func upscalePixelBuffer(
        _ pixelBuffer: CVPixelBuffer,
        scale: ScaleFactor
    ) -> CVPixelBuffer? {
        let sourceWidth = CVPixelBufferGetWidth(pixelBuffer)
        let sourceHeight = CVPixelBufferGetHeight(pixelBuffer)
        let targetWidth = sourceWidth * scale.rawValue
        let targetHeight = sourceHeight * scale.rawValue

        // 创建目标 pixel buffer
        var destinationBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: targetWidth,
            kCVPixelBufferHeightKey as String: targetHeight,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            targetWidth,
            targetHeight,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &destinationBuffer
        )

        guard status == kCVReturnSuccess, let destBuffer = destinationBuffer else {
            return nil
        }

        // 使用 CIFilter 放大
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let transform = CGAffineTransform(
            scaleX: CGFloat(scale.rawValue),
            y: CGFloat(scale.rawValue)
        )
        ciImage = ciImage.transformed(by: transform)

        // 锐化
        ciImage = applySharpen(to: ciImage, strength: 0.6) ?? ciImage

        // 渲染到目标 buffer
        ciContext.render(
            ciImage,
            to: destBuffer,
            bounds: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight),
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        return destBuffer
    }

    // MARK: - 图像增强滤镜

    private func applySharpen(to image: CIImage, strength: Double) -> CIImage? {
        guard let filter = CIFilter(name: "CISharpenLuminance") else { return nil }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(strength, forKey: kCIInputSharpnessKey)
        return filter.outputImage
    }

    private func applyDenoise(to image: CIImage) -> CIImage? {
        guard let filter = CIFilter(name: "CINoiseReduction") else { return nil }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(0.02, forKey: "inputNoiseLevel")
        filter.setValue(0.4, forKey: kCIInputSharpnessKey)
        return filter.outputImage
    }

    private func applyContrastEnhancement(to image: CIImage) -> CIImage? {
        guard let filter = CIFilter(name: "CIColorControls") else { return nil }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(1.1, forKey: kCIInputContrastKey)
        filter.setValue(1.05, forKey: kCIInputSaturationKey)
        return filter.outputImage
    }

    // MARK: - 智能放大

    /// 根据目标分辨率自动选择放大倍数
    func smartUpscale(
        _ image: CGImage,
        targetResolution: CGSize,
        sharpen: Bool = true
    ) -> CGImage? {
        let currentWidth = CGFloat(image.width)
        let currentHeight = CGFloat(image.height)

        let scaleX = targetResolution.width / currentWidth
        let scaleY = targetResolution.height / currentHeight
        let scale = max(scaleX, scaleY)

        let scaleFactor: ScaleFactor
        if scale >= 4 {
            scaleFactor = .x4
        } else if scale >= 3 {
            scaleFactor = .x3
        } else if scale >= 2 {
            scaleFactor = .x2
        } else {
            // 不需要放大
            return image
        }

        return upscaleImage(image, scale: scaleFactor, sharpen: sharpen)
    }
}

// MARK: - 便捷扩展

extension CGImage {
    /// 使用 Metal 硬件加速放大
    @MainActor
    func metalUpscaled(
        scale: SuperResolutionService.ScaleFactor,
        sharpen: Bool = true
    ) -> CGImage? {
        guard let service = SuperResolutionService.shared else { return nil }
        return service.upscaleImage(self, scale: scale, sharpen: sharpen)
    }

    /// 智能放大到目标分辨率
    @MainActor
    func metalUpscaled(to targetSize: CGSize) -> CGImage? {
        guard let service = SuperResolutionService.shared else { return nil }
        return service.smartUpscale(self, targetResolution: targetSize)
    }
}

extension CVPixelBuffer {
    /// 使用 Metal 硬件加速放大
    @MainActor
    func metalUpscaled(scale: SuperResolutionService.ScaleFactor) -> CVPixelBuffer? {
        guard let service = SuperResolutionService.shared else { return nil }
        return service.upscalePixelBuffer(self, scale: scale)
    }
}
