// Sources/Engine/ShaderPass.swift
import Foundation
import Metal

enum ShaderPassType: String, Codable {
    case filter
    case particle
    case postprocess
}

struct ShaderParameter: Identifiable, Codable {
    let id: UUID
    let key: String
    let name: String
    var value: Float
    let min: Float
    let max: Float
    let defaultValue: Float
}

protocol ShaderPassProtocol: AnyObject, Identifiable {
    var id: UUID { get }
    var name: String { get }
    var type: ShaderPassType { get }
    var enabled: Bool { get set }
    var parameters: [ShaderParameter] { get set }
    func execute(input: MTLTexture, commandBuffer: MTLCommandBuffer, device: MTLDevice) -> MTLTexture
}

final class ComputeShaderPass: ShaderPassProtocol {
    let id: UUID
    let name: String
    let type: ShaderPassType
    var enabled: Bool
    var parameters: [ShaderParameter]
    private var pipelineState: MTLComputePipelineState?
    private let functionName: String

    init(id: UUID = UUID(), name: String, type: ShaderPassType = .filter,
         functionName: String, parameters: [ShaderParameter]) {
        self.id = id
        self.name = name
        self.type = type
        self.enabled = false
        self.functionName = functionName
        self.parameters = parameters
    }

    func buildPipeline(device: MTLDevice, library: MTLLibrary) throws {
        guard let function = library.makeFunction(name: functionName) else {
            throw ShaderError.functionNotFound(functionName)
        }
        pipelineState = try device.makeComputePipelineState(function: function)
    }

    func execute(input: MTLTexture, commandBuffer: MTLCommandBuffer, device: MTLDevice) -> MTLTexture {
        guard enabled, let pipeline = pipelineState else { return input }

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: input.pixelFormat,
            width: input.width, height: input.height, mipmapped: false)
        descriptor.usage = [.shaderRead, .shaderWrite]
        guard let output = device.makeTexture(descriptor: descriptor) else { return input }

        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return input }
        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(input, index: 0)
        encoder.setTexture(output, index: 1)

        var params = parameters.map { $0.value }
        encoder.setBytes(&params, length: MemoryLayout<Float>.stride * params.count, index: 0)

        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (input.width + 15) / 16,
            height: (input.height + 15) / 16,
            depth: 1)
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        return output
    }
}

enum ShaderError: Error {
    case functionNotFound(String)
    case pipelineCreationFailed
}
