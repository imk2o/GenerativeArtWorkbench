//
//  FormImagePicker.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/28.
//

import SwiftUI
import UIKit
import PhotosUI

struct FormImagePicker: View {
    private let title: String
    private let image: Binding<CGImage?>

    @State private var droppedImage: CGImage?
    @State private var photosPickerItem: PhotosPickerItem?

    init(title: String = "", image: Binding<CGImage?>) {
        self.title = title
        self.image = image
    }
    
    var body: some View {
        HStack(alignment: .center) {
            if !title.isEmpty {
                Text(title)
                Spacer()
            }
            Group {
                if let image = image.wrappedValue {
                    Image(image, scale: 1, label: Text("Preview"))
                        .resizable()
                        .scaledToFit()
                } else {
                    Text("No image")
                }
            }
            .onDrop(of: [.image], delegate: ImageDropDelegate(image: $droppedImage))
            .onChange(of: droppedImage) { image in
                if let image {
                    self.image.wrappedValue = image
                }
            }
            .frame(width: 80, height: 80)
            .background(Color.secondary)
            .cornerRadius(4)
            
            PhotosPicker(selection: $photosPickerItem, matching: .images) {
                Text("Choose Image...")
            }
            .onChange(of: photosPickerItem) { item in
                Task {
                    if
                        let data = try? await item?.loadTransferable(type: Data.self),
                        let image = UIImage(data: data)
                    {
                        self.image.wrappedValue = image.cgImage
                    }
                }
            }
        }
    }
}
