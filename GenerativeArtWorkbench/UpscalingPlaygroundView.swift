//
//  UpscalingPlaygroundView.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/14.
//

import SwiftUI
import PhotosUI

import StewardSwiftUI

struct UpscalingPlaygroundView: View {
    @StateObject private var presenter = UpscalingPlaygroundPresenter()
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var droppedStaringImage: UIImage?
    @State private var previewItem: DocumentPreview.Item?
    
    var body: some View {
        HStack {
            VStack {
//                Text(presenter.progressSummary ?? "")
                Group {
                    if let image = presenter.previewImage {
                        Image(image, scale: 1, label: Text("Preview"))
                            .resizable()
                            .scaledToFit()
                            .onTapGesture { previewItem = .init(url: presenter.previewImageURL()) }
                            .documentPreview($previewItem)
                    } else {
                        Text("No image")
                    }
                }
                .frame(width: 400, height: 400)
                .background(Color.secondary)
                .cornerRadius(8)
                Form {
                    Section("Input Image") {
                        HStack(alignment: .center) {
                            Group {
                                if let image = presenter.inputImage {
                                    Image(image, scale: 1, label: Text("Preview"))
                                        .resizable()
                                        .scaledToFit()
                                } else {
                                    Text("No image")
                                }
                            }
                            .onDrop(of: [.image], delegate: ImageDropDelegate(image: $droppedStaringImage))
                            .onChange(of: droppedStaringImage) { image in
                                if let image {
                                    presenter.setInputImage(image)
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
                                        presenter.setInputImage(image)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Upscaing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(
                        action: {
                            Task { await presenter.run() }
                        },
                        label: {
                            Image(systemName: "play.fill")
                        }
                    )
                }
            }
            .toolbarRole(.editor)
        }
    }
    
    private struct ImageDropDelegate: DropDelegate {
        @Binding var image: UIImage?

        func performDrop(info: DropInfo) -> Bool {
            guard let item = info.itemProviders(for: [.image]).first else { return false }

            _ = item.loadTransferable(type: Data.self) { result in
                if
                    case .success(let data) = result,
                    let image = UIImage(data: data)
                {
                    Task { @MainActor in
                        self.image = image
                    }
                }
            }
            
            return true
        }
    }
}
