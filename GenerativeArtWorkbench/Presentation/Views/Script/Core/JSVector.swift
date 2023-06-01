//
//  JSVector.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/05/14.
//

import Foundation
import JavaScriptCore

@objc protocol JSVector: NSObjectProtocol, JSExport {
    var x: CGFloat { get }
    var y: CGFloat { get }
    var z: CGFloat { get }
    var w: CGFloat { get }
}

final class JSVectorImp: NSObject, JSVector {
    let vector: Vector4

    var x: CGFloat { vector.x }
    var y: CGFloat { vector.y }
    var z: CGFloat { vector.z }
    var w: CGFloat { vector.w }

    private init(vector: Vector4) {
        self.vector = vector
    }
    
    static func create(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat, _ w: CGFloat) -> JSVector {
        return JSVectorImp(vector: .init(
            x: x.isNaN ? 0 : x,
            y: y.isNaN ? 0 : y,
            z: z.isNaN ? 0 : z,
            w: w.isNaN ? 0 : w
        ))
    }
}
