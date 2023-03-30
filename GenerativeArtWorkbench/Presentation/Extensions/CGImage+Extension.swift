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
