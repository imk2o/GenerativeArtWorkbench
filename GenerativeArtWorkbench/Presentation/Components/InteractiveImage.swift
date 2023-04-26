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
struct InteractiveImage: View {
    // TODO: (AsyncImage like) ViewBuilder pattern
    init(_ image: CGImage, scale: CGFloat = 1, title: String) {
        self.image = image
        self.scale = scale
        self.title = title
    }
    
    @State private var previewItem: DocumentPreview.Item?
    private let image: CGImage
    private let scale: CGFloat
    private let title: String
    
    var body: some View {
        Image(image, scale: scale, label: Text(title))
            .resizable()
            .scaledToFit()
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
