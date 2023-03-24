//
//  DiffusionService.swift
//  StableDiffusionTest
//
//  Created by k2o on 2023/03/01.
//

import Foundation
import CoreML
import StableDiffusion

final class DiffusionService {
    enum Progress {
        case preparing
        case step(Int, image: CGImage?)
        case done(TimeInterval)
    }

    enum Error: Swift.Error {
        case generateImageFailed(Swift.Error?)
    }

    private class RunHolder: @unchecked Sendable {
        var isCancelled: Bool = false
        
        init() {}
    }
    
    private let pipeline: StableDiffusionPipeline

    init(
        directoryURL: URL,
        configuration: MLModelConfiguration,
        disableSafety: Bool = false,
        reduceMemory: Bool = true
    ) throws {
        pipeline = try StableDiffusionPipeline(
            resourcesAt: directoryURL,
            configuration: configuration,
            disableSafety: disableSafety,
            reduceMemory: reduceMemory
        )
    }
    
    func run(request: DiffusionRequest, progress handler: @escaping (Progress) -> Bool) async throws -> CGImage {
        let runHolder = RunHolder()
        return try await withTaskCancellationHandler(
            operation: {
                try await withCheckedThrowingContinuation { continuation in
                    do {
                        let startAt = Date()
                        _ = handler(.preparing)
                        print("diffusion start")
                        let images = try pipeline.generateImages(
                            configuration: request.configuration()
                        ) { progress in
                            print("diffusion progress: \(progress.step)")
                            guard !runHolder.isCancelled else {
                                return false
                            }
                            
                            let progressImage = request.generateProgressImage ?
                            progress.currentImages.compactMap({ $0 }).first : nil
                            print("diffusion progress image: \(progressImage)")
                            return handler(.step(progress.step, image: progressImage))
                        }
                        
                        guard let image = images.compactMap({ $0 }).first else {
                            print("diffusion error")
                            continuation.resume(throwing: Error.generateImageFailed(nil))
                            return
                        }

                        let duration = -startAt.timeIntervalSinceNow
                        _ = handler(.done(duration))
                        
                        continuation.resume(returning: image)
                        print("diffusion done")
                    } catch {
                        print("diffusion error")
                        continuation.resume(throwing: Error.generateImageFailed(error))
                    }
                }
            },
            onCancel: {
                runHolder.isCancelled = true
                print("diffusion cancel")
            }
        )
    }
}

private extension DiffusionRequest {
    func configuration() -> StableDiffusionPipeline.Configuration {
        var configuration = StableDiffusionPipeline.Configuration(prompt: prompt)
        configuration.negativePrompt = negativePrompt
        configuration.startingImage = startingImage
        configuration.strength = startingImageStrength
        configuration.imageCount = 1
        configuration.stepCount = stepCount
        configuration.seed = seed
        configuration.guidanceScale = guidanceScale
        configuration.disableSafety = true
        configuration.schedulerType = scheduler
        return configuration
    }
}
