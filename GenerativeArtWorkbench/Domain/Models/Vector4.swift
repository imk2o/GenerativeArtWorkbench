//
//  Vector4.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/28.
//

import CoreGraphics

struct Vector4 {
    var x: CGFloat
    var y: CGFloat
    var z: CGFloat
    var w: CGFloat
    
    static let zero = Vector4(x: 0, y: 0, z: 0, w: 0)
}

import CoreImage
extension Vector4 {
    init(_ vector: CIVector) {
        self.x = vector.x
        self.y = vector.y
        self.z = vector.z
        self.w = vector.w
    }
}

extension CIVector {
    convenience init(_ vector: Vector4) {
        self.init(x: vector.x, y: vector.y, z: vector.z, w: vector.w)
    }
}
