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
    private var diffusionService: DiffusionService?
    private let diffusionModelStore = DiffusionModelStore.shared
    
    init() {
    }

    @Published private(set) var modelConfiguration: DiffusionModelConfiguration?
    
    @Published var seed: UInt32 = 0
    @Published var randomSeed: Bool = true
    @Published var prompt: String = "realistic, masterpiece, girl highest quality, full body, looking at viewers, highres, indoors, detailed face and eyes, wolf ears, brown hair, short hair, silver eyes, necklace, sneakers, parka jacket, solo focus"
    @Published var negativePrompt: String = "lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry, artist name"
    @Published var stepCount: Int = 10
    @Published var guidanceScale: Float = 11
    @Published var startingImage: CGImage?
    @Published var startingImageStrength: Float = 0.8

    @Published private var controlNetInputImages: [String: CGImage] = [:]

    @Published private(set) var previewImage: CGImage?
    @Published private(set) var progressSummary: String?

    var inputSize: CGSize {
        // FIXME: モデルに応じて
        return CGSize(width: 512, height: 512)
    }
    private(set) lazy var controlNetDefaultImage: CGImage = .create(
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
    
    func controlNetInputImageBinding(for name: String) -> Binding<CGImage?> {
        return .init(
            get: { [self] in controlNetInputImage(for: name) },
            set: { [self] in setControlNetInputImage($0, for: name) }
        )
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
                    let image = controlNetInputImages[$0] ?? controlNetDefaultImage
                    return DiffusionRequest.ControlNetInput(name: $0, image: image)
                },
                generateProgressImage: true
            )
            
            let resultImage = try await diffusionService.run(request: request) { progress in
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
            
            try await DiffusionHistoryStore.shared.add(
                resultImage: resultImage,
                request: request,
                modelConfiguration: modelConfiguration
            )
            previewImage = resultImage
        } catch {
            guard !Task.isCancelled else {
                progressSummary = "Cancelled"
                return
            }

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
    
    func previewImageURL() -> URL? {
        guard let pngData = previewImagePngData() else { return nil }
        
        do {
            let fileURL = FileManager.default.temporaryFileURL(path: "\(UUID().uuidString).png")
            try pngData.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
    
    func previewImageDragItem() -> NSItemProvider {
        guard let pngData = previewImagePngData() else { return .init() }

        return .init(
            item: pngData as NSSecureCoding,
            typeIdentifier: UTType.png.identifier
        )
    }
    
    private func previewImagePngData() -> Data? {
        guard
            let previewImage,
            let pngData = UIImage(cgImage: previewImage).pngData()
        else {
            return nil
        }
        
        return pngData
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
