//
//  InteractiveImage.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/26.
//

import PhotosUI
import SwiftUI

import StewardSwiftUI

/// DragとPreviewに対応したImage
struct InteractiveImage<Content: View>: View {
    init(
        _ image: CGImage,
        scale: CGFloat = 1,
        title: String,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.image = image
        self.scale = scale
        self.title = title
        self.content = content
    }
    
    @State private var previewItem: DocumentPreview.Item?
    private let image: CGImage
    private let scale: CGFloat
    private let title: String
    private let content: (Image) -> Content

    var body: some View {
        content(Image(image, scale: scale, label: Text(title)))
            .onDrag { dragItem() }
            .onTapGesture { previewItem = .init(url: imageURL()) }
            .documentPreview($previewItem)
    }
    
    private func dragItem() -> NSItemProvider {
        guard let pngData = image.pngData() else { return .init() }

        return .init(
            item: pngData as NSSecureCoding,
            typeIdentifier: UTType.png.identifier
        )
    }
    
    func imageURL() -> URL? {
        guard let pngData = image.pngData() else { return nil }
        
        do {
            let fileURL = FileManager.default.temporaryFileURL(path: "\(title).png")
            try pngData.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }
}
