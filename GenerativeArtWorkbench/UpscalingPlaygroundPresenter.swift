//
//  UpscalingPlaygroundPresenter.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/14.
//

import SwiftUI
import Vision
import CoreImage

import CoreMLHelpers
import StewardFoundation
import StewardUIKit

@MainActor
final class UpscalingPlaygroundPresenter: ObservableObject {
    @Published var inputImage: CGImage?

    @Published private(set) var previewImage: CGImage?
    @Published private(set) var progressSummary: String?

    init(inputImage: CGImage? = nil) {
        if let inputImage {
            setInputImage(UIImage(cgImage: inputImage))
        }
    }

    private let ciContext = CIContext()
    
    func setInputImage(_ image: UIImage) {
        inputImage = image
            .aspectFilled(size: CGSize(width: 512, height: 512), imageScale: 1)
            .cgImage
    }
    
    func run() async {
        guard let inputImage else { return }
        
        do {
            let modelURL = FileManager.default.documentDirectory.appending(path: "realesrgan512.mlmodel")
            let modelcURL = try await MLModel.compileModel(at: modelURL)
            print("mlmodelc: \(modelcURL)")
            let model = try await MLModel.load(contentsOf: modelcURL)
            let vnModel = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: vnModel) { request, _ in
                if let observations = request.results as? [VNClassificationObservation] {
                    print(observations)
                }
            }
            request.imageCropAndScaleOption = .scaleFill
            request.usesCPUOnly = false
            
            let handler = VNImageRequestHandler(cgImage: inputImage)
            try handler.perform([request])
            
            let upscaledWidth = inputImage.width * 4
            let upscaledHeight = inputImage.height * 4
            guard
                let observation = request.results?.first as? VNPixelBufferObservation,
                let pixelBuffer = resizePixelBuffer(observation.pixelBuffer, width: upscaledWidth, height: upscaledHeight)
            else {
                return
            }
            
            previewImage = cgImage(from: pixelBuffer)
            
        } catch {
        }
    }
    
    private func cgImage(from pixelBuffer: CVPixelBuffer) -> CGImage? {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        return ciContext.createCGImage(
            CIImage(cvPixelBuffer: pixelBuffer),
            from: .init(x: 0, y: 0, width: width, height: height)
        )
    }
    
    func previewImageURL() -> URL? {
        guard
            let previewImage,
            let pngData = UIImage(cgImage: previewImage).pngData()
        else {
            return nil
        }
        
        do {
            let fileURL = FileManager.default.temporaryFileURL(path: "\(UUID().uuidString).png")
            try pngData.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
}
