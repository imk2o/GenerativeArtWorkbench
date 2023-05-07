//
//  FormTextField.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/05/07.
//

import SwiftUI

struct FormTextField: View {
    private let title: String
    private let text: Binding<String>
    
    init(
        title: String,
        text: Binding<String>
    ) {
        self.title = title
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
            Spacer()
            TextField(title, text: text)
                .frame(maxWidth: 480)
        }
    }
}
