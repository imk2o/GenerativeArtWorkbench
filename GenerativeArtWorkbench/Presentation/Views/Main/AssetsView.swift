//
//  AssetsView.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/30.
//

import SwiftUI

struct AssetsView: View {
    @State private var presenter = AssetsPresenter()
    @State private var droppedImage: CGImage?

    var body: some View {
        VStack {
            HStack {
                Text("Assets")
                Spacer()
                Button(
                    action: { Task { await presenter.browseAssetsFolder() } },
                    label: { Image(systemName: "folder.fill") }
                )
                .buttonStyle(BorderlessButtonStyle())
            }
            .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .background(Color.secondarySystemBackground)
            ScrollView {
                Group {
                    if presenter.assets.isEmpty {
                        Text("Drop here")
                            .foregroundColor(.secondaryLabel)
                            .frame(height: 200)
                    } else {
                        assetsGrid()
                            .padding()
                    }
                }
            }
            .onDrop(of: [.image], delegate: ImageDropDelegate(image: $droppedImage))
            .onChange(of: droppedImage) { _, image in
                if let image {
                    Task { await presenter.add(image: image) }
                }
            }
        }
        .task { await presenter.listen() }
    }
    
    private func assetsGrid() -> some View {
        LazyVGrid(
            columns: Array(repeating: .init(.flexible(), spacing: 2), count: 3),
            spacing: 2
        ) {
            ForEach(presenter.assets) { asset in
                AssetCell(asset)
                    .onDrag { presenter.dragItem(for: asset) }
            }
        }
    }
    
    private struct AssetCell: View {
        let asset: Asset
        
        init(_ asset: Asset) {
            self.asset = asset
        }
        
        var body: some View {
            AsyncImage(url: asset.url) { image in
                image
                    .resizable()
                    .scaledToFit()
//                        .draggable(image)
            } placeholder: {
                Rectangle()
                    .foregroundColor(Color.gray)
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }
}
