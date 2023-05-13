//
//  ImageFilter.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/05/05.
//

import Foundation
import CoreImage

struct ImageFilter: Identifiable {
    var id: String { name }
    let name: String

    enum Category: String, CaseIterable {
        case blur
        case colorAdjustment
        case colorEffect
        case compositeOperation
        case distortionEffect
        case generator
        case geometryAdjustment
        case gradient
        case halftoneEffect
        case reducion
        case sharpen
        case stylize
        case tileEffect
        case transition
    }
    let category: Category
    
    static let empty = ImageFilter(name: "", category: .blur)
}

extension ImageFilter.Category {
    init?(_ ciCategory: String) {
        switch ciCategory {
        case kCICategoryBlur:
            self = .blur
        case kCICategoryColorAdjustment:
            self = .colorAdjustment
        case kCICategoryColorEffect:
            self = .colorEffect
        case kCICategoryCompositeOperation:
            self = .compositeOperation
        case kCICategoryDistortionEffect:
            self = .distortionEffect
        case kCICategoryGenerator:
            self = .generator
        case kCICategoryGeometryAdjustment:
            self = .geometryAdjustment
        case kCICategoryGradient:
            self = .gradient
        case kCICategoryHalftoneEffect:
            self = .halftoneEffect
        case kCICategoryReduction:
            self = .reducion
        case kCICategorySharpen:
            self = .sharpen
        case kCICategoryStylize:
            self = .stylize
        case kCICategoryTileEffect:
            self = .tileEffect
        case kCICategoryTransition:
            self = .transition
        default:
            return nil
        }
    }
    
    var ciCategory: String {
        switch self {
        case .blur:
            return kCICategoryBlur
        case .colorAdjustment:
            return kCICategoryColorAdjustment
        case .colorEffect:
            return kCICategoryColorEffect
        case .compositeOperation:
            return kCICategoryCompositeOperation
        case .distortionEffect:
            return kCICategoryDistortionEffect
        case .generator:
            return kCICategoryGenerator
        case .geometryAdjustment:
            return kCICategoryGeometryAdjustment
        case .gradient:
            return kCICategoryGradient
        case .halftoneEffect:
            return kCICategoryHalftoneEffect
        case .reducion:
            return kCICategoryReduction
        case .sharpen:
            return kCICategorySharpen
        case .stylize:
            return kCICategoryStylize
        case .tileEffect:
            return kCICategoryTileEffect
        case .transition:
            return kCICategoryTransition
        }
    }
}
