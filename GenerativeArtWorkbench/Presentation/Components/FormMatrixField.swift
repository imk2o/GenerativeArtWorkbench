//
//  FormMatrixField.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/05/07.
//

import SwiftUI

struct FormMatrixField: View {
    let title: String
    @Binding var matrix: Matrix3
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            VStack {
                HStack {
                    Text("m11:")
                    TextField("M11", value: $matrix.m11, formatter: NumberFormatter())
                        .frame(maxWidth: 80)
                    Text("m12:")
                    TextField("M12", value: $matrix.m12, formatter: NumberFormatter())
                        .frame(maxWidth: 80)
                    Text("m13:")
                    TextField("M13", value: $matrix.m13, formatter: NumberFormatter())
                        .frame(maxWidth: 80)
                }
                HStack {
                    Text("m21:")
                    TextField("M21", value: $matrix.m21, formatter: NumberFormatter())
                        .frame(maxWidth: 80)
                    Text("m22:")
                    TextField("M22", value: $matrix.m22, formatter: NumberFormatter())
                        .frame(maxWidth: 80)
                    Text("m23:")
                    TextField("M23", value: $matrix.m23, formatter: NumberFormatter())
                        .frame(maxWidth: 80)
                }
                HStack {
                    Text("m31:")
                    TextField("M31", value: $matrix.m31, formatter: NumberFormatter())
                        .frame(maxWidth: 80)
                    Text("m32:")
                    TextField("M32", value: $matrix.m32, formatter: NumberFormatter())
                        .frame(maxWidth: 80)
                    Text("m33:")
                    TextField("M33", value: $matrix.m33, formatter: NumberFormatter())
                        .frame(maxWidth: 80)
                }
            }
        }
    }
}
