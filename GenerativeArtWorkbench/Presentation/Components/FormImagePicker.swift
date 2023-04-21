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
    private let defaultSketchImage: CGImage?
    
    @State private var droppedImage: CGImage?
    @State private var photosPickerItem: PhotosPickerItem?
    
    @State private var sketchItem: Sketch.Item
    @State private var isPhotosPickerPresented = false
    @State private var isSketchPresented = false

    private static let emptyImage: CGImage = .create(
        size: .init(width: 1, height: 1)
    )
    
    init(
        title: String = "",
        image: Binding<CGImage?>,
        defaultSketchImage: CGImage? = nil
    ) {
        self.title = title
        self.image = image
        self.defaultSketchImage = defaultSketchImage
        _sketchItem = .init(initialValue: .init(image: image.wrappedValue ??
            defaultSketchImage ??
            Self.emptyImage
        ))
    }
    
    var body: some View {
        HStack(alignment: .center) {
            if !title.isEmpty {
                Text(title)
                Spacer()
            }
            preview()
            actionButtons()
        }
    }

    private func preview() -> some View {
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
            applyImage(image)
        }
        .frame(width: 80, height: 80)
        .background(Color.secondary)
        .cornerRadius(4)
    }
    
    private func actionButtons() -> some View {
        VStack {
            Button(
                action: { isPhotosPickerPresented = true },
                label: { Image(systemName: "photo.on.rectangle") }
            )
            .photosPicker(
                isPresented: $isPhotosPickerPresented,
                selection: $photosPickerItem,
                matching: .images
            )
            .onChange(of: photosPickerItem) { item in
                Task {
                    if
                        let data = try? await item?.loadTransferable(type: Data.self),
                        let image = UIImage(data: data)
                    {
                        applyImage(image.cgImage)
                    }
                }
            }
            if defaultSketchImage != nil {
                Divider()
                    .frame(width: 16, height: 8)
                Button(
                    action: { isSketchPresented = true },
                    label: { Image(systemName: "pencil.and.outline") }
                )
                .sketch(
                    isPresented: $isSketchPresented,
                    item: $sketchItem
                )
                .onChange(of: sketchItem) { item in
                    // SketchView上の変更のみ反映
                    if isSketchPresented {
                        self.image.wrappedValue = item.image
                    }
                }
            }
            Divider()
                .frame(width: 16, height: 8)
            Button(
                action: { applyImage(nil) },
                label: { Image(systemName: "trash") }
            )
        }
        .buttonStyle(.borderless)
    }
    
    private func applyImage(_ image: CGImage?) {
        self.image.wrappedValue = image
        sketchItem = .init(
            image: image ?? defaultSketchImage ?? Self.emptyImage
        )
    }
}

private extension UIImage {
    static func create(
        size: CGSize,
        scale: CGFloat = 0,
        color: UIColor = .clear
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat.preferred()
        if scale > 0 {
            format.scale = scale
        }

        let image = UIGraphicsImageRenderer(size: size, format: format)
            .image { context in
                color.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }

        return image
    }
}

extension CGImage {
    static func create(
        size: CGSize,
        scale: CGFloat = 0,
        color: UIColor = .clear
    ) -> CGImage {
        return UIImage.create(size: size, scale: scale, color: color).cgImage!
    }
}
