//
//  VisionPlaygroundView.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/24.
//

import SwiftUI

import StewardSwiftUI

struct VisionPlaygroundView: View {
    init() {
        // https://stackoverflow.com/questions/62635914/initialize-stateobject-with-a-parameter-in-swiftui
        _presenter = .init(wrappedValue: .init())
    }
    
//    typealias Context = CoreMLPlaygroundPresenter.Context
    @StateObject private var presenter: VisionPlaygroundPresenter
    @State private var previewItem: DocumentPreview.Item?
    
    var body: some View {
        VStack {
            Group {
                if let image = presenter.outputImage {
                    InteractiveImage(image, title: presenter.selectedModel.name)
                } else {
                    Text("No image")
                }
            }
            .frame(width: 400, height: 400)
            .background(Color.secondary)
            .cornerRadius(8)
            Form {
                Section {
                    Picker(
                        "Model",
                        selection: Binding(
                            get: { presenter.selectedModel },
                            set: { model in Task { await presenter.setModel(model) } }
                        ),
                        content: {
                            ForEach(presenter.availableModels) { model in
                                Text(model.name)
                                    .tag(model)
                            }
                        }
                    )
                    //                        Button(action: { presenter.openModelDirectory() }, label: {
                    //                            Image(systemName: "folder.fill")
                    //                        })
                    //                        .buttonStyle(BorderlessButtonStyle())
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
