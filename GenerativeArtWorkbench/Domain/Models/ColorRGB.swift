//
//  ColorRGB.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/29.
//

import CoreGraphics

struct ColorRGB {
    var r: CGFloat
    var g: CGFloat
    var b: CGFloat
    var a: CGFloat
    
    static let transparent = ColorRGB(r: 0, g: 0, b: 0, a: 0)
    static let black = ColorRGB(r: 0, g: 0, b: 0, a: 1)
    static let white = ColorRGB(r: 1, g: 1, b: 1, a: 1)
}

import CoreImage
extension ColorRGB {
    init(_ color: CIColor) {
        self.r = color.red
        self.g = color.green
        self.b = color.blue
        self.a = color.alpha
    }
}

extension CIColor {
    convenience init(_ color: ColorRGB) {
        self.init(red: color.r, green: color.g, blue: color.b, alpha: color.a)
    }
}
