//
//  CGImage+Extension.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/26.
//

import Foundation
import CoreGraphics
import UIKit

extension CGImage {
    func writePNG(to url: URL) throws {
        guard let pngData = UIImage(cgImage: self).pngData() else {
            fatalError()
        }
        
        try pngData.write(to: url)
    }
}

extension CGImage {
    func normalized() -> CGImage {
        return UIImage(cgImage: self)
            .normalized()
            .cgImage!
    }
    
    func resized(maxSize: CGSize) -> CGImage {
        return UIImage(cgImage: self)
            .resized(maxSize: maxSize, imageScale: 1)
            .cgImage!
    }
    
    func aspectFilled(size: CGSize) -> CGImage {
        return UIImage(cgImage: self)
            .aspectFilled(size: size, imageScale: 1)
            .cgImage!
    }
}

