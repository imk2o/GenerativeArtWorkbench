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
        let line: Int
        
        init(_ exception: JSValue) {
            self.message = exception.toString() ?? "Unknown error"
            self.line = exception.toDictionary()["line"] as? Int ?? 0
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
        export()
    }
    
    func run(code: String) throws {
        jsContext.evaluateScript(code)
        if let exception = jsContext.exception {
            throw Exception(exception)
        }
    }

    private func export() {
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
    }
}
