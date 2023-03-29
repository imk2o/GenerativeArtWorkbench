//
//  CoreImagePlaygroundView.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/26.
//

import SwiftUI
import PhotosUI

import StewardSwiftUI

struct CoreImagePlaygroundView: View {
    typealias Context = CoreImagePlaygroundPresenter.Context
    @StateObject private var presenter: CoreImagePlaygroundPresenter

    @State private var previewItem: DocumentPreview.Item?
    
    init(context: Context = .new) {
        // https://stackoverflow.com/questions/62635914/initialize-stateobject-with-a-parameter-in-swiftui
        _presenter = .init(wrappedValue: .init(context: context))
    }

    var body: some View {
        HStack {
            VStack {
                Group {
                    if let image = presenter.resultImage {
                        Image(image, scale: 1, label: Text("Result"))
                            .resizable()
                            .scaledToFit()
                            .onTapGesture { previewItem = .init(url: presenter.resultImageURL()) }
                            .documentPreview($previewItem)
                    } else {
                        Text("No image")
                    }
                }
                .frame(width: 400, height: 400)
                .background(Color.secondary)
                .cornerRadius(8)
                Form {
                    Section {
                        Picker("Filter", selection: $presenter.selectedFilter, content: {
                            ForEach(presenter.availableFilters, id: \.self) { filter in
                                Text(filter)
                                    .tag(filter)
                            }
                        })
//                        Button(action: { presenter.openModelDirectory() }, label: {
//                            Image(systemName: "folder.fill")
//                        })
//                        .buttonStyle(BorderlessButtonStyle())
                    }
                    Section("Input") {
                        ForEach(presenter.inputAttributes) { attributes in
                            if let inputValueType = presenter.inputValueType(for: attributes) {
                                switch inputValueType {
                                case .number:
                                    FormSlider(
                                        title: attributes.displayName,
                                        value: presenter.inputNumberBinding(for: attributes.key),
                                        in: presenter.inputRange(for: attributes),
                                        step: presenter.inputPreferredStep(for: attributes)
                                    )
                                case .color:
                                    FormColorPicker(
                                        title: attributes.displayName,
                                        color: presenter.inputColorBinding(for: attributes)
                                    )
                                case .vector:
                                    FormVectorField(
                                        title: attributes.displayName,
                                        vector: presenter.inputVectorBinding(for: attributes)
                                    )
                                case .image:
                                    FormImagePicker(
                                        image: presenter.inputImageBinding(for: attributes)
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Core Image")
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
        .onAppear { Task { await presenter.prepare() } }
    }
}
