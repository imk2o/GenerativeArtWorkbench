//
//  FormSlider.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/28.
//

import SwiftUI

struct FormSlider<V>: View where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {
    private let title: String
    private let value: Binding<V>
    private let bounds: ClosedRange<V>
    private let step: V.Stride
    
    init(
        title: String,
        value: Binding<V>,
        in bounds: ClosedRange<V>,
        step: V.Stride
    ) {
        self.title = title
        self.value = value
        self.bounds = bounds
        self.step = step
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
            Spacer()
            Slider(value: value, in: bounds, step: step)
            Text(String(format: "%g", value.wrappedValue as! CVarArg))
        }
    }
}
