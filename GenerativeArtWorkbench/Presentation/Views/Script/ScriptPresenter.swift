//
//  ScriptPresenter.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/31.
//

import SwiftUI
import Combine

import CoreML

@MainActor
final class ScriptPresenter: ObservableObject {
    
    @Published var code: String = """
//async function run() {
//  const image = await genart.diffusion()
//  message(image)
//}
//
//run()
const gradient = genart.Filter("CILinearGradient", {});
//const final = genart.Filter("CIColorInvert", {"inputImage": gradient.outputImage});
const inputImage = genart.Image("image_2023-05-11_090933");
message(inputImage);
const final = genart.Filter("CIGaussianBlur", {"inputImage": inputImage});
const resultImage = final.render();
message("Result:");
message(resultImage);
"""
    @Published var error: String = "No error"
    
    enum Log {
        case string(String)
        case image(CGImage)
    }
    @Published private(set) var logs: [Log] = []

    private var cancellable = Set<AnyCancellable>()

    init() {
        
    }
    
    func prepare() async {
    }
    
    func run() async {
        do {
            let context = ScriptContext()
            context.$printMessage
                .sink { message in
                    if let message {
                        self.logs.append(message.toLog())
                    }
                }
                .store(in: &cancellable)
            
            try context.run(code: code)
        } catch let exception as ScriptContext.Exception {
            error = "\(exception.line): \(exception.message)"
        } catch {
            dump(error)
        }
    }
}

private extension ScriptContext.PrintMessage {
    func toLog() -> ScriptPresenter.Log {
        switch self {
        case .string(let string):
            return .string(string)
        case .image(let image):
            return .image(image.cgImage)
        }
    }
}
import JavaScriptCore
import CoreML

@objc protocol PackageJS: NSObjectProtocol, JSExport {
    static func print(_ value: JSValue)
    static func bar(_ value: Double) -> JSValue
    static func diffusion() -> JSValue
    static func Image(_ assetID: String) -> JSImage?
    static func Filter(_ name: String, _ params: [String: Any]?) -> JSFilter?
}

final class Package: NSObject, PackageJS {
    static func print(_ value: JSValue) {
        Swift.print(value.description)
    }

    static func bar(_ value: Double) -> JSValue {
        .init(newPromiseIn: JSContext.current()) { resolve, reject in
            resolve?.call(withArguments: [value * 10])
        }
    }

    static func diffusion() -> JSValue {
        .init(newPromiseIn: JSContext.current()) { resolve, reject in
            Task {
                guard let url = await DiffusionModelStore.shared.urls().first else {
                    reject?.call(withArguments: [])
                    return
                }
                let configuration = MLModelConfiguration()
                configuration.computeUnits = .cpuAndNeuralEngine
                
                let diffusionService = try DiffusionService(
                    directoryURL: url,
                    configuration: configuration, controlNets: []
                )
                let request = DiffusionRequest(
                    prompt: "realistic, masterpiece, girl highest quality, full body, looking at viewers, highres, indoors, detailed face and eyes, wolf ears, brown hair, short hair, silver eyes, necklace, sneakers, parka jacket, solo focus",
                    negativePrompt: "lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry, artist name",
                    stepCount: 10,
                    guidanceScale: 11
                )
                
                let image = try await diffusionService.run(request: request) { _ in true }
                
                resolve?.call(withArguments: [JSImageImp(cgImage: image)])
            }
        }
    }
    
    static func Image(_ assetID: String) -> JSImage? {
        return JSImageImp.create(assetID)
    }

    static func Filter(_ name: String, _ params: [String: Any]?) -> JSFilter? {
        return JSFilterImp.create(name, params)
    }
}

final class ScriptContext {
    struct Exception: Error {
        let message: String
        let line: Int
        
        init(_ exception: JSValue) {
            self.message = exception.toString() ?? "Unknonw error"
            self.line = exception.toDictionary()["line"] as? Int ?? 0
        }
    }

    enum PrintMessage {
        case string(String)
        case image(JSImageImp)
    }
    @Published private(set) var printMessage: PrintMessage?
    
    private let jsContext: JSContext

    init() {
        self.jsContext = JSContext()
        // FIXME: export
        let message: @convention(block) (JSValue) -> Void = { value in
            Task { @MainActor in
                if value.isString {
                    self.printMessage = .string(value.toString())
                } else {
                    switch value.toObject() {
                    case let image as JSImageImp:
                        self.printMessage = .image(image)
                    default:
                        break
                    }
                }
            }
        }
        jsContext.setObject(message, forKeyedSubscript: "message" as NSString)
        
        jsContext.setObject(Package.self, forKeyedSubscript: "genart" as NSString)
    }
    
    func run(code: String) throws {
        jsContext.evaluateScript(code)
        if let exception = jsContext.exception {
            throw Exception(exception)
        }
    }
}
