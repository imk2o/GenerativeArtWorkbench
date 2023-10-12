//
//  VisionPlaygroundView.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/24.
//

import SwiftUI

import StewardSwiftUI

struct VisionPlaygroundView: View {
    typealias Context = VisionPlaygroundPresenter.Context

    init(context: Context = .new) {
        presenter = .init(context: context)
    }
    
    private let presenter: VisionPlaygroundPresenter
    
    var body: some View {
        VStack {
            Group {
                if let image = presenter.outputImage {
                    InteractiveImage(image, title: presenter.selectedModel.name) { imageView in
                        imageView
                            .resizable()
                            .scaledToFit()
                    }
                } else {
                    Text("No image")
                }
            }
            .frame(width: 400, height: 400)
            .background(Color.secondary)
            .cornerRadius(8)
            Form {
                Section {
                    HStack {
                        Picker(
                            "Model",
                            selection: Binding(
                                get: { presenter.selectedModel },
                                set: { model in Task { await presenter.setModel(model) } }
                            ),
                            content: {
                                Text("(Unspecified)")
                                    .tag(VisionModel.empty)
                                ForEach(presenter.availableModels) { model in
                                    Text(model.name)
                                        .tag(model)
                                }
                            }
                        )
                        Button(
                            action: { Task { await presenter.browseModelFolder() } },
                            label: { Image(systemName: "folder.fill") }
                        )
                        .buttonStyle(BorderlessButtonStyle())
                        Divider()
                        Button(
                            action: { Task { await presenter.browseModelSite() } },
                            label: { Image(systemName: "globe") }
                        )
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                Section {
                    FormImagePicker(
                        title: "Input Image",
                        image: Binding(
                            get: { presenter.inputImage },
                            set: { presenter.setInputImage($0) }
                        )
                    )
                }
            }
        }
        .navigationTitle("Vision")
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
        .onAppear { Task { await presenter.prepare() } }
    }
}
