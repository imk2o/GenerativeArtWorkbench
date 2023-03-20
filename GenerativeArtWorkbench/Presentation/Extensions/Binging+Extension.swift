//
//  Binging+Extension.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/20.
//

import SwiftUI

// https://stackoverflow.com/questions/65736518/how-do-i-create-a-slider-in-swiftui-for-an-int-type-property

extension Binding where Value: BinaryInteger {
    /// Usage:
    /// @State private var count = 1
    /// Slider(value: $count.asFloat(), in: 1...10, step: 1)
    func asFloat<FloatValue: BinaryFloatingPoint>() -> Binding<FloatValue> {
        return .init(
            get: { FloatValue(wrappedValue) },
            set: { wrappedValue = Value($0) }
        )
    }
}

extension Binding where Value: BinaryFloatingPoint {
    func asInt<IntValue: BinaryInteger>() -> Binding<IntValue> {
        return .init(
            get: { IntValue(wrappedValue) },
            set: { wrappedValue = Value($0) }
        )
    }
}
