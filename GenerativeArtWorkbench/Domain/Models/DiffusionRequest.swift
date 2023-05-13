//
//  DiffusionRequest.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/22.
//

import Foundation
import CoreGraphics
import StableDiffusion

struct DiffusionRequest {
    let seed: UInt32
    let prompt: String
    let negativePrompt: String
    let startingImage: CGImage?
    let startingImageStrength: Float
    let stepCount: Int
    let guidanceScale: Float
    struct ControlNetInput {
        let name: String
        let image: CGImage
    }
    let controlNetInputs: [ControlNetInput]
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
        controlNetInputs: [ControlNetInput] = [],
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
        self.controlNetInputs = controlNetInputs
        self.scheduler = scheduler
        self.generateProgressImage = generateProgressImage
    }
}
