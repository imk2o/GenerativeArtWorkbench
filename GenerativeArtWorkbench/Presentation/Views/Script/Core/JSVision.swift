//
//  JSVision.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/05/21.
//

import Foundation
import JavaScriptCore

@objc protocol JSVisionProtocol: NSObjectProtocol, JSExport {
    func perform(_ inputImage: JSImageImp) -> JSValue
}

final class JSVision: NSObject, JSVisionProtocol {
    private let service: VisionService
    
    private init(service: VisionService) {
        self.service = service
    }
    
    func perform(_ inputImage: JSImageImp) -> JSValue {
        return .init(newPromiseIn: .current()) { [self] resolve, reject in
            Task {
                let outputImage = try await service.run(inputImage: inputImage.cgImage)
                
                resolve?.call(withArguments: [JSImageImp(cgImage: outputImage)])
            }
        }
    }

    static func create(_ modelID: String) -> JSValue {
        return .init(newPromiseIn: .current()) { resolve, reject in
            Task {
                guard let model = await VisionModelStore.shared.model(for: modelID) else {
                    reject?.call(withArguments: [JSValue(newErrorFromMessage: "Model not found: \(modelID)", in: .current())!])
                    return
                }
                
                let service = try await VisionService(with: model, configuration: .init())
                resolve?.call(withArguments: [JSVision(service: service)])
            }
        }
    }
}
