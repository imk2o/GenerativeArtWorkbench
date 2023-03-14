//
//  DiffusionPlaygroundPresenter.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/10.
//

import SwiftUI
import PhotosUI
import CoreML

import StewardFoundation
import StewardUIKit

@MainActor
final class DiffusionPlaygroundPresenter: ObservableObject {
    private let diffusionService: DiffusionService
    
    init() {
        let url = FileManager.default.documentDirectory.appending(path: "/MLModels")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)

        let configuration = MLModelConfiguration()
        configuration.computeUnits = .cpuAndNeuralEngine

        self.diffusionService = try! .init(
            directoryURL: url,
            configuration: configuration
        )
    }

    @Published var seed: UInt32 = 0
    @Published var randomSeed: Bool = true
    @Published var prompt: String = "realistic, masterpiece, girl highest quality, full body, looking at viewers, highres, indoors, detailed face and eyes, wolf ears, brown hair, short hair, silver eyes, necklace, sneakers, parka jacket, solo focus"
    @Published var negativePrompt: String = "lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry, artist name"
    @Published var stepCount: Float = 10
    @Published var guidanceScale: Float = 11
    @Published var startingImage: CGImage?
    @Published var startingImageStrength: Float = 0.8

    @Published private(set) var previewImage: CGImage?
    @Published private(set) var progressSummary: String?

    func setStartingImage(_ image: UIImage) {
        startingImage = image
            .aspectFilled(size: CGSize(width: 512, height: 512), imageScale: 1)
            .cgImage
    }
    
    func run() async {
        if randomSeed {
            seed = .random(in: 0...UInt32.max)
        }
        
        do {
            let request = DiffusionService.Request(
                seed: seed,
                prompt: prompt,
                negativePrompt: negativePrompt,
                startingImage: startingImage,
                startingImageStrength: startingImageStrength,
                stepCount: Int(stepCount),
                guidanceScale: guidanceScale,
                generateProgressImage: true
            )
            
            previewImage = try await diffusionService.run(request: request) { progress in
                dump(progress)
                Task.detached { @MainActor [self] in
                    switch progress {
                    case .preparing:
                        progressSummary = "Preparing..."
                    case .step(let step, let image):
                        if let image {
                            previewImage = image
                        }
                        progressSummary = "Step: \(step)"
                    case .done(let duration):
                        progressSummary = String(format: "Done: %gs", duration)
                    }
                }
                
                return true
            }
        } catch {
            guard !Task.isCancelled else {
                progressSummary = "Cancelled"
                return
            }

            dump(error)
        }
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
