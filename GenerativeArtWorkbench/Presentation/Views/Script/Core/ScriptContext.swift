//
//  ScriptContext.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/05/19.
//

import Foundation
import JavaScriptCore

final class ScriptContext {
    struct Exception: Error {
        let message: String
        let line: Int?
        
        init(message: String, line: Int?) {
            self.message = message
            self.line = line
        }
        
        init(_ exception: JSValue) {
            self.message = exception.toString() ?? "Unknown error"
            self.line = exception.toDictionary()["line"] as? Int
        }
    }

    enum InspectObject {
        case string(String)
        case number(Double)
        case image(JSImageImp)
    }
    @Published private(set) var inspectObject: InspectObject?
    
    private let jsContext: JSContext

    init() {
        self.jsContext = JSContext()
        exportFeatures()
    }
    
    func run(code: String, entry: String = "main") async throws {
        return try await withCheckedThrowingContinuation { continuation in
            let semaphore = DispatchSemaphore(value: 0)

            jsContext.evaluateScript(code)

            // https://stackoverflow.com/questions/74817895/how-to-await-async-js-function-inside-swift-using-javascriptcore-and-callback
            let onFulfilled: @convention(block) (JSValue) -> Void = { _ in
                semaphore.signal()
            }
            let onRejected: @convention(block) (JSValue) -> Void = { _ in
                semaphore.signal()
            }
            let entryFunction = jsContext.objectForKeyedSubscript(entry)
            entryFunction?.call(withArguments: []).invokeMethod(
                "then",
                withArguments: [
                    JSValue(object: onFulfilled, in: jsContext)!,
                    JSValue(object: onRejected, in: jsContext)!
                ]
            )

            _ = semaphore.wait(timeout: .distantFuture)

            if let exception = jsContext.exception {
                continuation.resume(throwing: Exception(exception))
            } else {
                continuation.resume()
            }
        }
    }

    private func exportFeatures() {
        // print
        let print: @convention(block) (JSValue) -> Void = { value in
            Swift.print(value.description)
        }
        jsContext.setObject(print, forKeyedSubscript: "print" as NSString)
        // inspect
        let inspect: @convention(block) (JSValue) -> Void = { value in
            Task { @MainActor in
                if value.isString {
                    self.inspectObject = .string(value.toString())
                } else if value.isNumber {
                    self.inspectObject = .number(value.toNumber().doubleValue)
                } else {
                    switch value.toObject() {
                    case let image as JSImageImp:
                        self.inspectObject = .image(image)
                    default:
                        break
                    }
                }
            }
        }
        jsContext.setObject(inspect, forKeyedSubscript: "inspect" as NSString)
        // art
        jsContext.setObject(JSPackageImp.self, forKeyedSubscript: "art" as NSString)
        
//        jsContext.exceptionHandler = { context, exception in
//            let errorDescription = exception.flatMap { $0.toString() } ?? "unknown"
//            NSLog("JSCoreImage Error: \(errorDescription)")
//        }
    }
}
