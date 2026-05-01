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

    init(screen: NSScreen, device: MTLDevice) throws {
        self.screenId = screen.localizedName
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

    func setWallpaper(url: URL) async throws {
        let decoder = VideoDecoder()
        try await decoder.load(url: url)
        self.videoDecoder = decoder
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

    nonisolated func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    nonisolated func draw(in view: MTKView) {
        MainActor.assumeIsolated {
            guard !isPaused,
                  let pixelBuffer = videoDecoder?.nextFrame(),
                  let textureCache = textureCache,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let drawable = view.currentDrawable,
                  let renderPipeline = renderPipelineState else { return }

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
