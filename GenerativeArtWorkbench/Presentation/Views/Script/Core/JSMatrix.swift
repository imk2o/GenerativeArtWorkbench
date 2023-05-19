//
//  JSMatrix.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/05/18.
//

import Foundation
import JavaScriptCore

@objc protocol JSMatrix: NSObjectProtocol, JSExport {
    func translated(_ x: CGFloat, _ y: CGFloat) -> JSMatrix
    func rotated(_ angle: CGFloat) -> JSMatrix
    func scaled(_ x: CGFloat, _ y: CGFloat) -> JSMatrix
}

final class JSMatrixImp: NSObject, JSMatrix {
    let matrix: Matrix3
    
    private init(matrix: Matrix3) {
        self.matrix = matrix
    }
    
    static func create() -> JSMatrix {
        return JSMatrixImp(matrix: .identity)
    }
    
    func translated(_ x: CGFloat, _ y: CGFloat) -> JSMatrix {
        return JSMatrixImp(matrix: matrix.translated(x: x, y: y))
    }
    
    func rotated(_ angle: CGFloat) -> JSMatrix {
        return JSMatrixImp(matrix: matrix.rotated(angle: angle))
    }
    
    func scaled(_ x: CGFloat, _ y: CGFloat) -> JSMatrix {
        return JSMatrixImp(matrix: matrix.scaled(x: x, y: y))
    }
}
