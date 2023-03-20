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

    @Published var seed: UInt32 = 0
    @Published var randomSeed: Bool = true
    @Published var prompt: String = "realistic, masterpiece, girl highest quality, full body, looking at viewers, highres, indoors, detailed face and eyes, wolf ears, brown hair, short hair, silver eyes, necklace, sneakers, parka jacket, solo focus"
    @Published var negativePrompt: String = "lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry, artist name"
    @Published var stepCount: Int = 10
    @Published var guidanceScale: Float = 11
    @Published var startingImage: CGImage?
    @Published var startingImageStrength: Float = 0.8

    struct DiffusionModel: Identifiable, Hashable {
        var id : String { name }
        let name: String
        let url: URL
        
        init(url: URL) {
            self.name = url.lastPathComponent
            self.url = url
        }

        private init(name: String, url: URL) {
            self.name = name
            self.url = url
        }

        static let empty = DiffusionModel(name: "(Not selected)", url: URL(string: "https://example.com")!)
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    @Published private(set) var availableModels: [DiffusionModel] = []
    @Published var selectedModel: DiffusionModel = .empty {
        didSet { setModel(selectedModel) }
    }

    @Published private(set) var previewImage: CGImage?
    @Published private(set) var progressSummary: String?

    func prepare() async {
        let urls = await diffusionModelStore.urls()
        availableModels = urls.map { DiffusionModel(url: $0) }
        if let model = availableModels.first {
            selectedModel = model
        }
    }
    
    func setStartingImage(_ image: UIImage) {
        startingImage = image
            .aspectFilled(size: CGSize(width: 512, height: 512), imageScale: 1)
            .cgImage
    }
    
    private func setModel(_ model: DiffusionModel) {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .cpuAndNeuralEngine
        
        self.diffusionService = try! .init(
            directoryURL: model.url,
            configuration: configuration
        )
    }
    
    func run() async {
        guard let diffusionService else { return }
        
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
