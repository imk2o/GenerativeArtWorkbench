//
//  UpscalingPlaygroundPresenter.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/14.
//

import SwiftUI

import StewardFoundation
import StewardUIKit

@MainActor
final class UpscalingPlaygroundPresenter: ObservableObject {
    @Published var inputImage: CGImage?

    @Published private(set) var previewImage: CGImage?
    @Published private(set) var progressSummary: String?

    private var upscalingService: UpscalingService?

    enum Context {
        case new
        case inputImage(CGImage)
    }
    
    init(context: Context = .new) {
        self.context = context
    }

    private let context: Context

    func prepare() async {
        do {
//            let modelcURL = FileManager.default.documentDirectory.appending(path: "MMRealSRGAN.mlmodelc")
            let modelcURL = FileManager.default.documentDirectory.appending(path: "realesrgan512.mlmodelc")
            upscalingService = try await .init(with: modelcURL, configuration: .init())
            
            if case .inputImage(let inputImage) = context {
                setInputImage(UIImage(cgImage: inputImage))
            }
        } catch {
            dump(error)
        }
    }
    
    func setInputImage(_ image: UIImage) {
        guard let upscalingService else { return }
        
        inputImage = image
            .aspectFilled(size: upscalingService.inputSize, imageScale: 1)
            .cgImage
    }
    
    func run() async {
        guard let inputImage, let upscalingService else { return }
        
        do {
            previewImage = try await upscalingService.run(inputImage: inputImage)
        } catch {
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
