//
//  ImageFilterStore.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/05/05.
//

import Foundation
import CoreImage

final class ImageFilterStore {
    static let shared = ImageFilterStore()
    
    private init() {
        
    }
    
    func imageFilters() async -> [ImageFilter] {
        return ImageFilter.Category.allCases
            .reduce(into: [ImageFilter]()) { filters, category in
                filters += CIFilter
                    .filterNames(inCategory: category.ciCategory)
                    .map { ImageFilter(name: $0, category: category) }
            }
    }
}
