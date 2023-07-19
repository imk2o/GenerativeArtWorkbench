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
import StewardSwiftUI

@MainActor
final class DiffusionPlaygroundPresenter: ObservableObject {
    private var diffusionService: DiffusionService?
    private let diffusionModelStore = DiffusionModelStore.shared
    
    init() {
    }

    enum Progress {
        case preparing
        case step(Float)
        case done(String)
    }
    @Published private(set) var progress: Progress?
    @Published var issueAlert: IssueAlert = .empty
    
    @Published private(set) var modelConfiguration: DiffusionModelConfiguration? {
        didSet {
            modelConfigurationData = {
                if let modelConfiguration {
                    return try? JSONEncoder().encode(modelConfiguration)
                } else {
                    return nil
                }
            }()
        }
    }
    
    @Published var seed: UInt32 = 0
    @Published var randomSeed: Bool = true
    @Published var prompt: String = "realistic, masterpiece, girl highest quality, full body, looking at viewers, highres, indoors, detailed face and eyes, wolf ears, brown hair, short hair, silver eyes, necklace, sneakers, parka jacket, solo focus"
    @Published var negativePrompt: String = "lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry, artist name"
    @Published var stepCount: Int = 10
    @Published var guidanceScale: Float = 11
    @Published private(set) var startingImage: CGImage?
    @Published var startingImageStrength: Float = 0.8

    @Published private var controlNetInputImages: [String: CGImage] = [:]

    @Published private(set) var previewImage: CGImage?
    @Published private(set) var progressSummary: String?

    @AppStorage("playgroundModelConfiguration")
    private var modelConfigurationData: Data?
    
    var inputSize: CGSize {
        // FIXME: モデルに応じて
        return CGSize(width: 512, height: 512)
    }
    private(set) lazy var defaultStartingImage: CGImage = .create(
        size: inputSize,
        scale: 1,
        color: .black
    )
    private(set) lazy var defaultControlNetImage: CGImage = .create(
        size: inputSize,
        scale: 1,
        color: .black
    )

    private var availableModels: [DiffusionModel] = []
    private func model(for id: String) -> DiffusionModel? {
        return availableModels.first { $0.id == id }
    }
    
    func prepare() async {
        let urls = await diffusionModelStore.urls()
        availableModels = urls.map { DiffusionModel(url: $0) }
        
        // 選択モデルの復元
        if
            let modelConfigurationData,
            let modelConfiguration = try? JSONDecoder().decode(DiffusionModelConfiguration.self, from: modelConfigurationData)
        {
            setModelConfiguration(modelConfiguration)
        }
    }
    
    func setStartingImage(_ image: CGImage?) {
        startingImage = image?.aspectFilled(size: inputSize)
    }

    func setModelConfiguration(_ modelConfiguration: DiffusionModelConfiguration) {
        guard let model = model(for: modelConfiguration.modelID) else { return }
        
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .init(modelConfiguration.computeUnits)

        self.diffusionService = try! .init(
            directoryURL: model.url,
            configuration: configuration,
            controlNets: modelConfiguration.controlNets,
            disableSafety: true,
            reduceMemory: false
        )

        self.modelConfiguration = modelConfiguration
    }

    func controlNetInputImage(for name: String) -> CGImage? {
        return controlNetInputImages[name]
    }
    
    func setControlNetInputImage(_ image: CGImage?, for name: String) {
        // TODO: align 512x512
        controlNetInputImages[name] = image?.aspectFilled(size: inputSize)
    }
    
    func run() async {
        guard
            let modelConfiguration,
            let diffusionService
        else { return }
        
        if randomSeed {
            seed = .random(in: 0...UInt32.max)
        }
        
        do {
            let request = DiffusionRequest(
                seed: seed,
                prompt: prompt,
                negativePrompt: negativePrompt,
                startingImage: startingImage,
                startingImageStrength: startingImageStrength,
                stepCount: Int(stepCount),
                guidanceScale: guidanceScale,
                controlNetInputs: modelConfiguration.controlNets.map {
                    let image = controlNetInputImages[$0] ?? defaultControlNetImage
                    return DiffusionRequest.ControlNetInput(name: $0, image: image)
                },
                generateProgressImage: true
            )
            
            let resultImage = try await diffusionService.run(request: request) { progress in
                dump(progress)
                Task.detached { @MainActor [self] in
                    switch progress {
                    case .preparing:
                        self.progress = .preparing
                        progressSummary = "Preparing..."
                    case .step(let step, let image):
                        if let image {
                            previewImage = image
                        }
                        self.progress = .step(Float(step) / Float(request.stepCount))
                        progressSummary = "Step: \(step)"
                    case .done(let duration):
                        self.progress = .done(String(format: "Done: %gs", duration))
                        Task {
                            try? await Task.sleep(nanoseconds: 1_000_000_000)
                            self.progress = nil
                        }
                        progressSummary = String(format: "Done: %gs", duration)
                    }
                }
                
                return true
            }
            
            try await DiffusionHistoryStore.shared.add(
                resultImage: resultImage,
                request: request,
                modelConfiguration: modelConfiguration
            )
            previewImage = resultImage
            issueAlert = .empty
        } catch {
            guard !Task.isCancelled else {
                progressSummary = "Cancelled"
                return
            }

            issueAlert = .init(error: error)
            progress = nil
            dump(error)
        }
    }
    
    func configure(with history: DiffusionHistory) async {
        seed = history.request.seed
        randomSeed = false
        prompt = history.request.prompt
        negativePrompt = history.request.negativePrompt
        stepCount = history.request.stepCount
        guidanceScale = history.request.guidanceScale
        // Starting imageの復元
        if
            let url = history.request.startingImageURL,
            let data = try? Data(contentsOf: url),
            let image = UIImage(data: data)?.cgImage
        {
            setStartingImage(image)
        } else {
            setStartingImage(nil)
        }
        // ControlNetの入力画像の復元
        controlNetInputImages = [:]
        history.request.controlNetInputImageURLs.forEach { name, url in
            if
                let data = try? Data(contentsOf: url),
                let image = UIImage(data: data)?.cgImage
            {
                setControlNetInputImage(image, for: name)
            }
        }
        
        startingImageStrength = history.request.startingImageStrength
        setModelConfiguration(history.modelConfiguration)
        
        previewImage = nil
        progressSummary = nil
    }
    
    func openModelDirectory() {
        openDirectory(url: diffusionModelStore.baseURL)
    }
    
    func openSite() {
        openURL(.init(string: "https://huggingface.co/coreml")!)
    }
}

extension DiffusionModel: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension MLComputeUnits {
    init(_ computeUnits: DiffusionModelConfiguration.ComputeUnits) {
        switch computeUnits {
        case .all:
            self = .all
        case .cpu:
            self = .cpuOnly
        case .cpuGPU:
            self = .cpuAndGPU
        case .cpuNE:
            self = .cpuAndNeuralEngine
        }
    }
}
