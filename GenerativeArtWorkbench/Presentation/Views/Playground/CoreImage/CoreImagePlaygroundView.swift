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

    init(context: Context = .new) {
        // https://stackoverflow.com/questions/62635914/initialize-stateobject-with-a-parameter-in-swiftui
        _presenter = .init(wrappedValue: .init(context: context))
    }

    var body: some View {
        HStack {
            VStack {
                Group {
                    if let image = presenter.resultImage {
                        InteractiveImage(image, title: presenter.selectedFilter.name) { imageView in
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
                            Text("Filter")
                            Menu {
                                ForEach(ImageFilter.Category.allCases, id: \.self) { category in
                                    if let filters = presenter.availableFilters[category] {
                                        Menu(category.ciCategory) {
                                            ForEach(filters) { filter in
                                                Button(filter.name) { presenter.selectedFilter = filter }
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    Text(presenter.selectedFilter.name)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.footnote)
                                }
                                .foregroundColor(.secondaryLabel)
                            }
                        }
                    }
                    Section("Input") {
                        ForEach(presenter.inputAttributes) { attributes in
                            inputField(for: attributes)
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
    
    private func inputField(for attributes: CIFilter.InputAttributes) -> some View {
        Group {
            switch presenter.inputValueType(for: attributes) {
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
                    title: attributes.displayName,
                    image: presenter.inputImageBinding(for: attributes)
                )
            case .string:
                FormTextField(
                    title: attributes.displayName,
                    text: Binding(
                        get: { presenter.inputString(for: attributes) },
                        set: { presenter.setInputString($0, for: attributes) }
                    )
                )
            case .matrix:
                FormMatrixField(
                    title: attributes.displayName,
                    matrix: Binding(
                        get: { presenter.inputMatrix(for: attributes) },
                        set: { presenter.setInputMatrix($0, for: attributes) }
                    )
                )
            case .unknown(let type):
                HStack {
                    Text(type)
                    Spacer()
                    Text("(Unknown type: \(type))")
                        .foregroundColor(.secondaryLabel)
                }
            }
        }
    }
}
