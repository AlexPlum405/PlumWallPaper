// Sources/Engine/ScreenRenderer.swift
import Foundation
import Metal
import MetalKit
import CoreVideo

@MainActor
final class ScreenRenderer: NSObject, MTKViewDelegate {
    let screenId: String
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let desktopWindow: DesktopWindow

    private var videoDecoder: VideoDecoder?
    private var shaderGraph: ShaderGraph?
    private var textureCache: CVMetalTextureCache?
    private var renderPipelineState: MTLRenderPipelineState?
    private var isPaused = false

    /// 当前壁纸 ID (用于 RestoreManager / SlideshowScheduler)
    private(set) var currentWallpaperId: UUID?
    /// 静音状态
    private(set) var isMuted: Bool = false

    // MARK: - FPS 测量
    private var frameCount: Int = 0
    private var lastFPSSampleTime: CFTimeInterval = 0
    /// 实测渲染帧率
    private(set) var measuredFPS: Double = 0

    init(screen: NSScreen, screenId: String, device: MTLDevice) throws {
        self.screenId = screenId
        self.device = device
        guard let queue = device.makeCommandQueue() else {
            throw RendererError.noCommandQueue
        }
        self.commandQueue = queue
        self.desktopWindow = DesktopWindow(screen: screen, device: device)

        var cache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(nil, nil, device, nil, &cache)
        self.textureCache = cache

        super.init()

        self.shaderGraph = try ShaderGraph(device: device)
        try buildRenderPipeline()
        desktopWindow.mtkView.delegate = self
        lastFPSSampleTime = CACurrentMediaTime()
    }

    private func buildRenderPipeline() throws {
        guard let library = device.makeDefaultLibrary(),
              let vertexFunc = library.makeFunction(name: "fullscreenVertex"),
              let fragFunc = library.makeFunction(name: "textureFragment") else {
            throw RendererError.shaderNotFound
        }
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vertexFunc
        desc.fragmentFunction = fragFunc
        desc.colorAttachments[0].pixelFormat = desktopWindow.mtkView.colorPixelFormat
        renderPipelineState = try device.makeRenderPipelineState(descriptor: desc)
    }

    func setWallpaper(url: URL, wallpaperId: UUID? = nil) async throws {
        let decoder = VideoDecoder()
        try await decoder.load(url: url)
        self.videoDecoder = decoder
        self.currentWallpaperId = wallpaperId
        desktopWindow.mtkView.isPaused = false
        desktopWindow.mtkView.preferredFramesPerSecond = Int(decoder.nominalFrameRate)
        desktopWindow.show()
    }

    func pause() {
        isPaused = true
        desktopWindow.mtkView.isPaused = true
    }

    func resume() {
        isPaused = false
        desktopWindow.mtkView.isPaused = false
    }

    // MARK: - Audio

    func setMuted(_ muted: Bool) {
        isMuted = muted
        videoDecoder?.setMuted(muted)
    }

    // MARK: - FPS / Opacity

    func setFPSLimit(_ limit: Int) {
        if limit > 0 {
            desktopWindow.mtkView.preferredFramesPerSecond = limit
        } else if let decoder = videoDecoder {
            desktopWindow.mtkView.preferredFramesPerSecond = Int(decoder.nominalFrameRate)
        }
    }

    func setOpacity(_ alpha: CGFloat) {
        desktopWindow.alphaValue = alpha
    }

    // MARK: - MTKViewDelegate

    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    nonisolated func draw(in view: MTKView) {
        MainActor.assumeIsolated {
            guard !isPaused,
                  let pixelBuffer = videoDecoder?.nextFrame(),
                  let textureCache = textureCache,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let drawable = view.currentDrawable,
                  let renderPipeline = renderPipelineState else { return }

            // FPS 测量
            frameCount += 1
            let now = CACurrentMediaTime()
            let elapsed = now - lastFPSSampleTime
            if elapsed >= 1.0 {
                measuredFPS = Double(frameCount) / elapsed
                frameCount = 0
                lastFPSSampleTime = now
            }

            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)

            var cvTexture: CVMetalTexture?
            CVMetalTextureCacheCreateTextureFromImage(
                nil, textureCache, pixelBuffer, nil,
                .bgra8Unorm, width, height, 0, &cvTexture)

            guard let cvTex = cvTexture,
                  let inputTexture = CVMetalTextureGetTexture(cvTex) else { return }

            let finalTexture = shaderGraph?.execute(input: inputTexture, commandBuffer: commandBuffer) ?? inputTexture

            guard let renderPassDesc = view.currentRenderPassDescriptor else { return }
            guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDesc) else { return }
            encoder.setRenderPipelineState(renderPipeline)
            encoder.setFragmentTexture(finalTexture, index: 0)
            encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            encoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }

    func cleanup() {
        videoDecoder?.cleanup()
        desktopWindow.hide()
    }
}

enum RendererError: Error {
    case noCommandQueue
    case shaderNotFound
}
