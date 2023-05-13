//
//  FormVectorField.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/28.
//

import SwiftUI

struct FormVectorField: View {
    let title: String
    @Binding var vector: Vector4
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("x:")
            TextField("X", value: $vector.x, formatter: NumberFormatter())
                .frame(maxWidth: 80)
            Text("y:")
            TextField("Y", value: $vector.y, formatter: NumberFormatter())
                .frame(maxWidth: 80)
            Text("z:")
            TextField("Z", value: $vector.z, formatter: NumberFormatter())
                .frame(maxWidth: 80)
            Text("w:")
            TextField("W", value: $vector.w, formatter: NumberFormatter())
                .frame(maxWidth: 80)
        }
    }
}
