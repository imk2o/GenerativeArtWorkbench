//
//  JSPackage.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/05/19.
//

import Foundation
import JavaScriptCore

@objc protocol JSPackage: NSObjectProtocol, JSExport {
    static func bar(_ value: Double) -> JSValue
//    static func diffusion() -> JSValue
    static func Image(_ assetID: String) -> JSImage?
    static func Filter(_ name: String, _ params: [String: Any]?) -> JSFilter?
    static func Vector(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat, _ w: CGFloat) -> JSVector
    static func Color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> JSColor
    static func Matrix() -> JSMatrix
    static func Vision(_ modelID: String) -> JSValue
    static func Diffusion(_ modelID: String, _ params: [String: Any]?) -> JSValue
}

final class JSPackageImp: NSObject, JSPackage {
    static func bar(_ value: Double) -> JSValue {
        .init(newPromiseIn: JSContext.current()) { resolve, reject in
            resolve?.call(withArguments: [value * 10])
        }
    }

//    static func diffusion() -> JSValue {
//        .init(newPromiseIn: JSContext.current()) { resolve, reject in
//            Task {
//                guard let url = await DiffusionModelStore.shared.urls().first else {
//                    reject?.call(withArguments: [])
//                    return
//                }
//                let configuration = MLModelConfiguration()
//                configuration.computeUnits = .cpuAndNeuralEngine
//
//                let diffusionService = try DiffusionService(
//                    directoryURL: url,
//                    configuration: configuration, controlNets: []
//                )
//                let request = DiffusionRequest(
//                    prompt: "realistic, masterpiece, girl highest quality, full body, looking at viewers, highres, indoors, detailed face and eyes, wolf ears, brown hair, short hair, silver eyes, necklace, sneakers, parka jacket, solo focus",
//                    negativePrompt: "lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry, artist name",
//                    stepCount: 10,
//                    guidanceScale: 11
//                )
//
//                let image = try await diffusionService.run(request: request) { _ in true }
//
//                resolve?.call(withArguments: [JSImageImp(cgImage: image)])
//            }
//        }
//    }
    
    static func Image(_ assetID: String) -> JSImage? {
        return JSImageImp.create(assetID)
    }

    static func Filter(_ name: String, _ params: [String: Any]?) -> JSFilter? {
        return JSFilterImp.create(name, params)
    }
    
    static func Vector(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat, _ w: CGFloat) -> JSVector {
        return JSVectorImp.create(x, y, z, w)
    }
    
    static func Color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> JSColor {
        return JSColorImp.create(r, g, b, a)
    }
    
    static func Matrix() -> JSMatrix {
        return JSMatrixImp.create()
    }
    
    static func Vision(_ modelID: String) -> JSValue {
        return JSVision.create(modelID)
    }
    
    static func Diffusion(_ modelID: String, _ params: [String: Any]?) -> JSValue {
        return JSDiffusion.create(modelID, params)
    }
}
