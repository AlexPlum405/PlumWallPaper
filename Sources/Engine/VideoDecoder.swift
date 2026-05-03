// Sources/Engine/VideoDecoder.swift
import Foundation
import AVFoundation
import CoreVideo
import Metal

@MainActor
final class VideoDecoder {
    private var asset: AVAsset?
    private var videoTrack: AVAssetTrack?
    private var reader: AVAssetReader?
    private var output: AVAssetReaderTrackOutput?
    private var displayLink: CVDisplayLink?
    private var isLooping = true
    private var isPaused = false
    private var playbackRate: Float = 1.0

    var onFrame: ((CVPixelBuffer) -> Void)?
    var onEnd: (() -> Void)?

    private(set) var duration: Double = 0
    private(set) var currentTime: Double = 0
    private(set) var nominalFrameRate: Float = 30

    func load(url: URL) async throws {
        let asset = AVURLAsset(url: url)
        self.asset = asset

        let duration = try await asset.load(.duration)
        self.duration = CMTimeGetSeconds(duration)

        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw VideoDecoderError.noVideoTrack
        }

        self.nominalFrameRate = try await track.load(.nominalFrameRate)
        self.videoTrack = track

        try setupReader(asset: asset, track: track)
    }

    private func setupReader(asset: AVAsset, track: AVAssetTrack, startTime: CMTime = .zero) throws {
        let reader = try AVAssetReader(asset: asset)
        if startTime > .zero {
            let totalDuration = CMTime(seconds: duration, preferredTimescale: 600)
            let remainingDuration = CMTimeSubtract(totalDuration, startTime)
            reader.timeRange = CMTimeRange(start: startTime, duration: remainingDuration)
        }
        let settings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
        output.alwaysCopiesSampleData = false

        guard reader.canAdd(output) else {
            throw VideoDecoderError.cannotAddOutput
        }
        reader.add(output)
        reader.startReading()

        self.reader = reader
        self.output = output
        self.currentTime = max(0, CMTimeGetSeconds(startTime))
    }

    func nextFrame() -> CVPixelBuffer? {
        guard !isPaused, let output = output, let reader = reader else { return nil }

        if reader.status == .completed {
            if isLooping {
                try? restartReader()
                return self.output?.copyNextSampleBuffer().flatMap { sampleBuffer in
                    currentTime = max(0, CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)))
                    return CMSampleBufferGetImageBuffer(sampleBuffer)
                }
            } else {
                onEnd?()
                return nil
            }
        }

        guard let sampleBuffer = output.copyNextSampleBuffer() else { return nil }
        currentTime = max(0, CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)))
        return CMSampleBufferGetImageBuffer(sampleBuffer)
    }

    private func restartReader() throws {
        reader?.cancelReading()
        guard let asset, let track = videoTrack else { return }
        try setupReader(asset: asset, track: track)
    }

    func pause() { isPaused = true }
    func resume() { isPaused = false }
    func setLooping(_ loop: Bool) { isLooping = loop }
    func setRate(_ rate: Float) { playbackRate = rate }
    func setMuted(_ muted: Bool) {
        // 当前使用 AVAssetReader 解码，音频由 ScreenRenderer 控制
        // 此标志供上层查询用
        isMuted = muted
    }
    private(set) var isMuted: Bool = false

    func seek(to fraction: Double) {
        guard let asset else { return }
        let clamped = min(max(fraction, 0), 1)
        let seconds = duration * clamped
        let time = CMTime(seconds: seconds, preferredTimescale: 600)

        reader?.cancelReading()
        guard let track = videoTrack else { return }
        do {
            try setupReader(asset: asset, track: track, startTime: time)
        } catch {
            try? restartReader()
        }
    }

    func cleanup() {
        reader?.cancelReading()
        reader = nil
        output = nil
        asset = nil
        videoTrack = nil
    }
}

enum VideoDecoderError: Error {
    case noVideoTrack
    case cannotAddOutput
}
