//
//  DiffusionPlaygroundView.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/08.
//

import SwiftUI
import PhotosUI

import StewardSwiftUI

struct DiffusionPlaygroundView: View {
    @StateObject private var presenter = DiffusionPlaygroundPresenter()
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var droppedStaringImage: UIImage?
    @State private var previewItem: DocumentPreview.Item?
    
    var body: some View {
        HStack {
            VStack {
                Text(presenter.progressSummary ?? "")
                Group {
                    if let image = presenter.previewImage {
                        Image(image, scale: 1, label: Text("Preview"))
                            .resizable()
                            .scaledToFit()
                            .onDrag { presenter.previewImageDragItem() }
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
                    Section("Prompt") {
                        TextEditor(text: $presenter.prompt)
                            .frame(minHeight: 80)
                        TextEditor(text: $presenter.negativePrompt)
                            .frame(minHeight: 80)
                    }
                    Section("Parameter") {
                        HStack(alignment: .center, spacing: 8) {
                            Text("Seed")
                            Spacer()
                            TextField("", value: $presenter.seed, format: .number)
                                .disabled(presenter.randomSeed)
                            Toggle("Random", isOn: $presenter.randomSeed)
                        }

                        HStack(alignment: .center, spacing: 8) {
                            Text("Step")
                            Spacer()
                            Slider(
                                value: $presenter.stepCount,
                                in: 1...50,
                                step: 1
                            )
                            Text("\(presenter.stepCount)")
                        }
                        HStack(alignment: .center, spacing: 8) {
                            Text("Guidance")
                            Spacer()
                            Slider(
                                value: $presenter.guidanceScale,
                                in: 0...20,
                                step: 0.1
                            )
                            Text("\(presenter.guidanceScale)")
                        }
                    }
                    Section("Staring Image") {
                        HStack(alignment: .center) {
                            Group {
                                if let image = presenter.startingImage {
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
                                    presenter.setStartingImage(image)
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
                                        presenter.setStartingImage(image)
                                    }
                                }
                            }
                        }
                        
                        HStack(alignment: .center) {
                            Text("Strength")
                            Spacer()
                            Slider(
                                value: $presenter.startingImageStrength,
                                in: 0...1,
                                step: 0.01
                            )
                            Text("\(presenter.startingImageStrength)")
                        }
                    }
                }
            }
            .navigationTitle("Diffusion")
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
            Divider()
            List {
                Text("FIXME: History")
            }
            .frame(width: 320)
        }
    }
}
