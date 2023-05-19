//
//  JSColor.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/05/14.
//

import Foundation
import JavaScriptCore

@objc protocol JSColor: NSObjectProtocol, JSExport {
    var r: CGFloat { get }
    var g: CGFloat { get }
    var b: CGFloat { get }
    var a: CGFloat { get }
}

final class JSColorImp: NSObject, JSColor {
    let color: ColorRGB
    private init(color: ColorRGB) {
        self.color = color
    }
    
    var r: CGFloat { color.r }
    var g: CGFloat { color.g }
    var b: CGFloat { color.b }
    var a: CGFloat { color.a }
    
    static func create(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> JSColor {
        return JSColorImp(color: .init(
            r: r,
            g: g,
            b: b,
            a: a.isNaN ? 1 : a
        ))
    }

}
