//
//  AssetsView.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/30.
//

import SwiftUI

struct AssetsView: View {
    @StateObject private var presenter = AssetsPresenter()
    @State private var droppedImage: CGImage?

    var body: some View {
        Group {
            if presenter.assets.isEmpty {
                Text("Drop here")
                    .foregroundColor(.secondaryLabel)
                    .frame(height: 200)
            } else {
                assetsGrid()
            }
        }
        .task { await presenter.prepare() }
        .onDrop(of: [.image], delegate: ImageDropDelegate(image: $droppedImage))
        .onChange(of: droppedImage) { image in
            if let image {
                Task { await presenter.add(image: image) }
            }
        }
    }
    
    private func assetsGrid() -> some View {
        LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3)) {
            ForEach(presenter.assets) { asset in
                AsyncImage(url: asset.url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .onDrag { presenter.dragItem(for: asset) }
                } placeholder: {
                    Rectangle()
                        .foregroundColor(Color.gray)
                }
                .aspectRatio(.init(width: 1, height: 1), contentMode: .fill)
                .cornerRadius(4)
            }
        }
    }
}
