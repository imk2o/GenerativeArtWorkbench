//
//  VisionPlaygroundPresenter.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/24.
//

import SwiftUI

@MainActor
final class VisionPlaygroundPresenter: ObservableObject {
    enum Context: Hashable {
        case new
        case inputImage(CGImage)
    }
    let context: Context

    init(context: Context = .new) {
        self.context = context
    }

    @Published private(set) var availableModels: [VisionModel] = []
    @Published private(set) var selectedModel: VisionModel = .empty
    @Published private(set) var inputImage: CGImage?

    @Published private(set) var outputImage: CGImage?

    private var visionService: VisionService?
    private let visionModelStore = VisionModelStore.shared
    private func model(for id: String) -> VisionModel? {
        return availableModels.first { $0.id == id }
    }

    func prepare() async {
        availableModels = await visionModelStore.models()
//        // 選択モデルの復元
//        if
//            let modelConfigurationData,
//            let modelConfiguration = try? JSONDecoder().decode(DiffusionModelConfiguration.self, from: modelConfigurationData)
//        {
//            setModelConfiguration(modelConfiguration)
//        }
        
        if case .inputImage(let inputImage) = context {
            setInputImage(inputImage)
        }
    }
    
    func setModel(_ model: VisionModel) async {
        guard model != .empty else { return }
        
        do {
            visionService = try await .init(
                with: model,
                configuration: .init()
            )
            selectedModel = model
        } catch {
            dump(error)
        }
    }

    func setInputImage(_ image: CGImage?) {
        inputImage = image
    }
    
    func run() async {
        guard let inputImage, let visionService else { return }
        
        do {
            outputImage = try await visionService.run(
                inputImage: inputImage.aspectFilled(size: visionService.inputSize)
            )
        } catch {
            dump(error)
        }
    }
    
    func previewImageURL() -> URL? {
        guard
            let outputImage,
            let pngData = UIImage(cgImage: outputImage).pngData()
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
    
    func browseModelFolder() async {
        openDirectory(url: visionModelStore.baseURL)
    }
    
    func browseModelSite() async {
        openURL(.init(string: "https://github.com/john-rocky/CoreML-Models")!)
    }
}

extension VisionModel: Hashable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
