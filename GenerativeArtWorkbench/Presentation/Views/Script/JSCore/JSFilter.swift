//
//  JSFilter.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/05/14.
//

import Foundation
import JavaScriptCore
import CoreImage

@objc protocol JSFilter: NSObjectProtocol, JSExport {
    static func create(_ name: String, _ params: [String: Any]?) -> JSFilter?
    
    var outputImage: JSValue { get }
    
    func render() -> JSImage?
}

final class JSFilterImp: NSObject, JSFilter {
    let ciFilter: CIFilter
    init(ciFilter: CIFilter) {
        self.ciFilter = ciFilter
    }
    
    static func create(_ name: String, _ params: [String: Any]?) -> JSFilter? {
        guard let ciFilter = CIFilter(name: name, parameters: params?.converted()) else { return nil }
        return JSFilterImp(ciFilter: ciFilter)
    }

    var outputImage: JSValue { .init(object: ciFilter.outputImage, in: .current()) }

    func render() -> JSImage? {
        guard let ciImage = ciFilter.outputImage else { return nil }
        
        let ciContext = CIContext()	// FIXME
//        let extent = CGRect(x: 0, y: 0, width: 2048, height: 2048)	// FIXME
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return nil }

        return JSImageImp(cgImage: cgImage)
    }
}

private extension Dictionary where Key == String, Value == Any {
    func converted() -> Self {
        return compactMapValues { value in
            switch value {
            case let image as JSImageImp:
                return CIImage(cgImage: image.cgImage)//.clampedToExtent()
            default:
                return value
            }
        }
    }
}
