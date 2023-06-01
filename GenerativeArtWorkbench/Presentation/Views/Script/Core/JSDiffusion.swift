//
//  JSDiffusion.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/05/23.
//

import Foundation
import JavaScriptCore
import CoreML

@objc protocol JSDiffusionProtocol: NSObjectProtocol, JSExport {
    func perform(_ request: [String: Any], _ progressHandler: JSValue?) -> JSValue
}

final class JSDiffusion: NSObject, JSDiffusionProtocol {
    private let service: DiffusionService
    
    private init(service: DiffusionService) {
        self.service = service
    }
    
    static func create(_ modelID: String, _ params: [String: Any]?) -> JSValue {
        let context = JSContext.current()
        return .init(newPromiseIn: context) { resolve, reject in
            Task {
                guard let model = await DiffusionModelStore.shared.model(for: modelID) else {
                    reject?.call(withArguments: [JSValue(newErrorFromMessage: "Model not found: \(modelID)", in: context)!])
                    return
                }
                
                let configuration = MLModelConfiguration()
                configuration.computeUnits = .cpuAndNeuralEngine
                let service = try DiffusionService(
                    directoryURL: model.url,
                    configuration: configuration,
                    controlNets: params?["controlNets"] as? [String] ?? [],
                    disableSafety: true,
                    reduceMemory: false
                )
                resolve?.call(withArguments: [JSDiffusion(service: service)])
            }
        }
    }
    
    func perform(_ request: [String: Any], _ progressHandler: JSValue?) -> JSValue {
        return .init(newPromiseIn: .current()) { [self] resolve, reject in
            let request = DiffusionRequest(
                seed: request["seed"] as? UInt32 ?? .random(in: 0...UInt32.max),
                prompt: request["prompt"] as? String ?? "",
                negativePrompt: request["negativePrompt"] as? String ?? "",
                startingImage: (request["startingImage"] as? JSImageImp)?.cgImage,
                startingImageStrength: request["startingImageStrength"] as? Float ?? 0.7,
                stepCount: request["stepCount"] as? Int ?? 20,
                guidanceScale: request["guidanceScale"] as? Float ?? 11,
                controlNetInputs: (request["controlNetInputs"] as? [[String: Any]] ?? []).compactMap { params in
                    guard
                        let name = params["name"] as? String,
                        let image = params["image"] as? JSImageImp
                    else {
                        return nil
                    }
                    
                    return .init(name: name, image: image.cgImage)
                },
                //scheduler: <#T##StableDiffusionScheduler#>,
                generateProgressImage: request["generateProgressImage"] as? Bool ?? true
            )
            
            Task {
                let image = try await service.run(request: request) { progress in
                    if
                        let progressHandler,
                        case .step(let step, let image) = progress
                    {
                        var params: [String: Any] = [:]
                        params["step"] = step
                        if let image {
                            params["image"] = JSImageImp(cgImage: image)
                        }
                        progressHandler.call(withArguments: [params])
                    }
                    return true
                }
                
                resolve?.call(withArguments: [JSImageImp(cgImage: image)])
            }
        }
    }
}
