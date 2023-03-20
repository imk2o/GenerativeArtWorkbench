//
//  DiffusionService.swift
//  StableDiffusionTest
//
//  Created by k2o on 2023/03/01.
//

import Foundation
import CoreGraphics
import CoreML
import StableDiffusion

final class DiffusionService {
    struct Request {
        let seed: UInt32
        let prompt: String
        let negativePrompt: String
        let startingImage: CGImage?
        let startingImageStrength: Float
        let stepCount: Int
        let guidanceScale: Float
        let scheduler: StableDiffusionScheduler
        let generateProgressImage: Bool

        init(
            seed: UInt32 = .random(in: 0...UInt32.max),
            prompt: String,
            negativePrompt: String = "",
            startingImage: CGImage? = nil,
            startingImageStrength: Float = 0.7,
            stepCount: Int = 20,
            guidanceScale: Float = 11,
            scheduler: StableDiffusionScheduler = .dpmSolverMultistepScheduler,
            generateProgressImage: Bool = false
        ) {
            self.seed = seed
            self.prompt = prompt
            self.negativePrompt = negativePrompt
            self.startingImage = startingImage
            self.startingImageStrength = startingImageStrength
            self.stepCount = stepCount
            self.guidanceScale = guidanceScale
            self.scheduler = scheduler
            self.generateProgressImage = generateProgressImage
        }
    }
    
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
    
    func run(request: Request, progress handler: @escaping (Progress) -> Bool) async throws -> CGImage {
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

private extension DiffusionService.Request {
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
