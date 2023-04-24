//
//  VisionService.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/24.
//

import Foundation
import Vision
import CoreImage
import CoreMLHelpers

final class VisionService {
    enum Error: Swift.Error {
        case decodingFailed(Swift.Error?)
    }

    init(
        with model: VisionModel,
        configuration: MLModelConfiguration
    ) async throws {
        var modelURL = model.url
        if modelURL.pathExtension == "mlmodel" {
            modelURL = try await MLModel.compileModel(at: modelURL)
        }
        self.mlModel = try await MLModel.load(contentsOf: modelURL, configuration: configuration)
        self.vnModel = try VNCoreMLModel(for: mlModel)
    }

    private let mlModel: MLModel
    private let vnModel: VNCoreMLModel
    private let ciContext = CIContext()

    var inputSize: CGSize {
        return mlModel.modelDescription.inputDescriptionsByName.values
            .compactMap(\.imageConstraint)
            .first
            .flatMap { CGSize(width: $0.pixelsWide, height: $0.pixelsHigh) } ?? .zero
    }
    
    var outputSize: CGSize {
        return mlModel.modelDescription.outputDescriptionsByName.values
            .compactMap(\.imageConstraint)
            .first
            .flatMap { CGSize(width: $0.pixelsWide, height: $0.pixelsHigh) } ?? .zero
    }

    func run(inputImage: CGImage) async throws -> CGImage {
        let request = VNCoreMLRequest(model: vnModel) { request, _ in
            if let observations = request.results as? [VNClassificationObservation] {
                print(observations)
            }
        }
        request.imageCropAndScaleOption = .scaleFill
        request.usesCPUOnly = false
        
        let handler = VNImageRequestHandler(cgImage: inputImage)
        try handler.perform([request])
        
        let upscaledSize = outputSize
        guard
            let observation = request.results?.first as? VNPixelBufferObservation,
            let pixelBuffer = resizePixelBuffer(observation.pixelBuffer, width: Int(upscaledSize.width), height: Int(upscaledSize.height))
        else {
            throw Error.decodingFailed(nil)
        }
        
        guard let upscaledImage = ciContext.createCGImage(
            CIImage(cvPixelBuffer: pixelBuffer),
            from: .init(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        ) else {
            throw Error.decodingFailed(nil)
        }
        
        return upscaledImage
    }
}
