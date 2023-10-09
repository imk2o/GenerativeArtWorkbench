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
    @State private var isSelectModelSheetPresented = false

    var body: some View {
        VStack {
            Group {
                if let image = presenter.previewImage {
                    InteractiveImage(image, title: presenter.modelConfiguration?.modelID ?? "") { imageView in
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
                        Text("Model")
                        Spacer()
                        Text(presenter.modelConfiguration?.modelID ?? "(Unspecified)")
                            .foregroundColor(.secondaryLabel)
                        Button("Select...") {
                            isSelectModelSheetPresented = true
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .sheet(isPresented: $isSelectModelSheetPresented) {
                            DiffusionPlaygroundSelectModelSheet(presenter.modelConfiguration) {
                                presenter.setModelConfiguration($0)
                            }
                        }
                    }
                }
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

                    FormSlider(
                        title: "Step",
                        value: $presenter.stepCount.asFloat(),
                        in: 1...50,
                        step: 1
                    )
                    FormSlider(
                        title: "Guidance",
                        value: $presenter.guidanceScale,
                        in: 0...20,
                        step: 0.1
                    )
                }
                Section("Staring Image") {
                    FormImagePicker(
                        title: "Starting Image",
                        image: Binding(
                            get: { presenter.startingImage },
                            set: { presenter.setStartingImage($0) }
                        ),
                        defaultSketchImage: presenter.defaultStartingImage
                    )
                    FormSlider(
                        title: "Strength",
                        value: $presenter.startingImageStrength,
                        in: 0...1,
                        step: 0.01
                    )
                }
                if
                    let modelConfiguration = presenter.modelConfiguration,
                    !modelConfiguration.controlNets.isEmpty
                {
                    controlNetSection(modelConfiguration)
                }
            }
        }
        .navigationTitle("Diffusion")
        .navigationBarTitleDisplayMode(.inline)
        .alert($presenter.issueAlert)
        .inspector(isPresented: .constant(true)) {
            DiffusionPlaygroundHistoryView(onTap: { history in
                Task { await presenter.configure(with: history) }
            })
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if let progress = presenter.progress {
                    Group {
                        switch progress {
                        case .preparing:
                            IndeterminateCircularProgressView()
                        case .step(let ratio):
                            CircularProgressView(progress: ratio)
                        case .done:
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .frame(width: 24, height: 24)
                } else {
                    Button(
                        action: {
                            Task { await presenter.run() }
                        },
                        label: {
                            Image(systemName: "play.fill")
                        }
                    )
                    .keyboardShortcut("r")
                }
            }
        }
        .toolbarRole(.editor)
        .task { await presenter.prepare() }
    }
    
    private func controlNetSection(_ modelConfiguration: DiffusionModelConfiguration) -> some View {
        Section("Control Net") {
            ForEach(modelConfiguration.controlNets, id: \.self) { controlNet in
                FormImagePicker(
                    title: controlNet,
                    image: Binding(
                        get: { presenter.controlNetInputImage(for: controlNet) },
                        set: { presenter.setControlNetInputImage($0, for: controlNet) }
                    ),
                    defaultSketchImage: presenter.defaultControlNetImage
                )
            }
        }
    }
}
