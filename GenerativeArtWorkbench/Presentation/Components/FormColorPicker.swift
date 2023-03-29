//
//  FormColorPicker.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/29.
//

import SwiftUI

struct FormColorPicker: View {
    let title: String
    @Binding var color: ColorRGB

    var body: some View {
        ColorPicker(title, selection: $color.asSwiftUIColor())
    }
}

private extension Binding where Value == ColorRGB {
    func asSwiftUIColor() -> Binding<Color> {
        return .init(
            get: { Color(wrappedValue) },
            set: { wrappedValue = ColorRGB($0) }
        )
    }

}

private extension Color {
    init(_ color: ColorRGB) {
        self.init(red: color.r, green: color.g, blue: color.b, opacity: color.a)
    }
    
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) {
        var components: (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) = (0, 0, 0, 0)
        
        UIColor(self).getRed(
            &components.red,
            green: &components.green,
            blue: &components.blue,
            alpha: &components.opacity
        )
        
        return components
    }
    
    var red: CGFloat { components.red }
    var green: CGFloat { components.green }
    var blue: CGFloat { components.blue }
    var opacity: CGFloat { components.opacity }
}

private extension ColorRGB {
    init(_ color: Color) {
        self.init(r: color.red, g: color.green, b: color.blue, a: color.opacity)
    }
}
