//
//  UpscalingService.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/19.
//

import Foundation
import Vision
import CoreImage

import CoreMLHelpers

final class UpscalingService {
    enum Error: Swift.Error {
        case decodingFailed(Swift.Error?)
    }
    
    static func service(
        with modelURL: URL,
        configuration: MLModelConfiguration = .init()
    ) async throws -> Self {
//        let modelcURL = try await MLModel.compileModel(at: modelURL)
        let mlModel = try await MLModel.load(contentsOf: modelURL, configuration: configuration)
        let vnModel = try VNCoreMLModel(for: mlModel)
        return Self.init(mlModel: mlModel, vnModel: vnModel)
    }
    
    private init(mlModel: MLModel, vnModel: VNCoreMLModel) {
        self.mlModel = mlModel
        self.vnModel = vnModel
    }

    private let mlModel: MLModel
    private let vnModel: VNCoreMLModel
    private let ciContext = CIContext()

    var inputSize: CGSize {
        return mlModel.modelDescription.inputDescriptionsByName.values
            .compactMap { featureDescription -> MLImageConstraint? in
                if featureDescription.type == .image {
                    return featureDescription.imageConstraint
                } else {
                    return nil
                }
            }
            .first
            .flatMap { CGSize(width: $0.pixelsWide, height: $0.pixelsHigh) } ?? .zero
    }
    
    var outputSize: CGSize {
        return mlModel.modelDescription.outputDescriptionsByName.values
            .compactMap { featureDescription -> MLImageConstraint? in
                if featureDescription.type == .image {
                    return featureDescription.imageConstraint
                } else {
                    return nil
                }
            }
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
