//
//  JSImage.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/05/14.
//

import Foundation
import JavaScriptCore
import CoreGraphics

@objc protocol JSImage: NSObjectProtocol, JSExport {
    static func create(_ assetID: String) -> JSImage?
}

final class JSImageImp: NSObject, JSImage {
    let cgImage: CGImage
    
    init(cgImage: CGImage) {
        self.cgImage = cgImage
    }
    
    static func create(_ assetID: String) -> JSImage? {
        guard
            let asset = AssetStore.shared.asset(for: assetID),
            let image = asset.image()
        else {
            return nil
        }
        
        return JSImageImp(cgImage: image)
    }
}
