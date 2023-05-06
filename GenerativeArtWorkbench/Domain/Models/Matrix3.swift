//
//  Matrix3.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/05/07.
//

import CoreGraphics

struct Matrix3 {
    var m11: CGFloat
    var m12: CGFloat
    var m13: CGFloat
    var m21: CGFloat
    var m22: CGFloat
    var m23: CGFloat
    var m31: CGFloat
    var m32: CGFloat
    var m33: CGFloat
    
    static let identity = Matrix3(
        m11: 1, m12: 0, m13: 0,
        m21: 0, m22: 1, m23: 0,
        m31: 0, m32: 0, m33: 1
    )
}

extension Matrix3 {
    init(_ transform: CGAffineTransform) {
        self.m11 = transform.a
        self.m12 = transform.b
        self.m13 = 0
        self.m21 = transform.c
        self.m22 = transform.d
        self.m23 = 0
        self.m31 = transform.tx
        self.m32 = transform.ty
        self.m33 = 1
    }
}

extension CGAffineTransform {
    init(_ matrix: Matrix3) {
        self.init(
            matrix.m11, matrix.m12,
            matrix.m21, matrix.m22,
            matrix.m31, matrix.m32
        )
    }
}
