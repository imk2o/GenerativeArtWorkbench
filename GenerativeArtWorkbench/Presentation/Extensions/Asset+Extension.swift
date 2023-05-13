//
//  Asset+Extension.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/05/14.
//

import UIKit

extension Asset {
    func image() -> CGImage? {
        guard
            let data = try? Data(contentsOf: url),
            let image = UIImage(data: data)
        else {
            return nil
        }
        
        return image.cgImage
    }
}
