// Sources/Services/VideoEnhancementService.swift
import Foundation
import AVFoundation
import VideoToolbox
import CoreVideo

/// VideoToolbox 硬件加速视频增强服务
@MainActor
final class VideoEnhancementService {
    static let shared = VideoEnhancementService()

    private var session: VTPixelTransferSession?

    private init() {
        var sessionOut: VTPixelTransferSession?
        let status = VTPixelTransferSessionCreate(
            allocator: kCFAllocatorDefault,
            pixelTransferSessionOut: &sessionOut
        )

        if status == noErr, let session = sessionOut {
            self.session = session
            print("[VideoEnhancement] VideoToolbox 会话创建成功")
        } else {
            print("[VideoEnhancement] VideoToolbox 会话创建失败: \(status)")
        }
    }

    // MARK: - 像素格式转换

    /// 使用 VideoToolbox 硬件加速转换像素格式
    func convertPixelBuffer(
        _ sourceBuffer: CVPixelBuffer,
        to targetFormat: OSType = kCVPixelFormatType_32BGRA
    ) -> CVPixelBuffer? {
        guard let session = session else { return nil }

        let sourceWidth = CVPixelBufferGetWidth(sourceBuffer)
        let sourceHeight = CVPixelBufferGetHeight(sourceBuffer)

        var destinationBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: targetFormat,
            kCVPixelBufferWidthKey as String: sourceWidth,
            kCVPixelBufferHeightKey as String: sourceHeight,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            sourceWidth,
            sourceHeight,
            targetFormat,
            attributes as CFDictionary,
            &destinationBuffer
        )

        guard status == kCVReturnSuccess, let destBuffer = destinationBuffer else {
            return nil
        }

        let transferStatus = VTPixelTransferSessionTransferImage(
            session,
            from: sourceBuffer,
            to: destBuffer
        )

        return transferStatus == noErr ? destBuffer : nil
    }

    // MARK: - 视频缩放

    /// 使用 VideoToolbox 硬件加速缩放视频帧
    func scalePixelBuffer(
        _ sourceBuffer: CVPixelBuffer,
        to targetSize: CGSize
    ) -> CVPixelBuffer? {
        guard let session = session else { return nil }

        let targetWidth = Int(targetSize.width)
        let targetHeight = Int(targetSize.height)

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

        // 设置缩放质量
        VTSessionSetProperty(
            session,
            key: kVTPixelTransferPropertyKey_ScalingMode,
            value: kVTScalingMode_Trim as CFTypeRef
        )

        let transferStatus = VTPixelTransferSessionTransferImage(
            session,
            from: sourceBuffer,
            to: destBuffer
        )

        return transferStatus == noErr ? destBuffer : nil
    }

    deinit {
        if let session = session {
            VTPixelTransferSessionInvalidate(session)
        }
    }
}
