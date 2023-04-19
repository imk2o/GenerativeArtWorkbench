//
//  DiffusionPlaygroundSelectModelSheet.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/13.
//

import SwiftUI

struct DiffusionPlaygroundSelectModelSheet: View {
    init(
        _ configuration: DiffusionModelConfiguration? = nil,
        onSelect: @escaping (DiffusionModelConfiguration) -> Void
    ) {
        _presenter = .init(wrappedValue: .init(configuration))
        self.onSelect = onSelect
    }
    
    @StateObject private var presenter: DiffusionPlaygroundSelectModelPresenter
    let onSelect: (DiffusionModelConfiguration) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    modelSection()
                    controlNetSection()
                }
            }
            .navigationTitle("Select Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("OK") {
                        onSelect(presenter.currentConfiguration)
                        dismiss()
                    }
                }
            }
            .task { await presenter.prepare() }
        }
    }
    
    private func modelSection() -> some View {
        Section {
            HStack {
                Picker("Model", selection: $presenter.selectedModel, content: {
                    ForEach(presenter.availableModels) { model in
                        Text(model.name)
                            .tag(model)
                    }
                })
                Button(action: { presenter.openModelDirectory() }, label: {
                    Image(systemName: "folder.fill")
                })
                .buttonStyle(BorderlessButtonStyle())
                Divider()
                Button(action: { presenter.openSite() }, label: {
                    Image(systemName: "globe")
                })
                .buttonStyle(BorderlessButtonStyle())
            }
            HStack {
                Text("Compute Unit")
                Spacer(minLength: 32)
                Picker("Compute Unit", selection: $presenter.selectedComputeUnits, content: {
                    Text("CPU")
                        .tag(DiffusionModelConfiguration.ComputeUnits.cpu)
                    Text("CPU & GPU")
                        .tag(DiffusionModelConfiguration.ComputeUnits.cpuGPU)
                    Text("CPU & NE")
                        .tag(DiffusionModelConfiguration.ComputeUnits.cpuNE)
                    Text("All")
                        .tag(DiffusionModelConfiguration.ComputeUnits.all)
                })
                .pickerStyle(SegmentedPickerStyle())
            }
        }
    }
    
    private func controlNetSection() -> some View {
        Section("Control Net") {
            if presenter.selectedModel.controlNets.isEmpty {
                HStack {
                    Spacer()
                    Text("Unavailable")
                    Spacer()
                }
            } else {
                ForEach(presenter.selectedModel.controlNets, id: \.self) { controlNet in
                    HStack {
                        Text(controlNet)
                        Spacer()
                        if presenter.selectedControlNets.contains(controlNet) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .background(Button(
                        action: { presenter.toggleSelection(controlNet: controlNet) },
                        label: { EmptyView() }
                    ))
                }
            }
        }
    }
}

@MainActor
final class DiffusionPlaygroundSelectModelPresenter: ObservableObject {
    init(_ configuration: DiffusionModelConfiguration?) {
        self.initialConfiguration = configuration
    }
    
    @Published private(set) var availableModels: [DiffusionModel] = []
    @Published var selectedModel: DiffusionModel = .empty {
        didSet { selectedControlNets = .init() }
    }
    @Published var selectedComputeUnits: DiffusionModelConfiguration.ComputeUnits = .all
    @Published var selectedControlNets: Set<String> = []
    
    var currentConfiguration: DiffusionModelConfiguration {
        return .init(
            modelID: selectedModel.id,
            controlNets: Array(selectedControlNets),
            computeUnits: selectedComputeUnits
        )
    }
    
    private let initialConfiguration: DiffusionModelConfiguration?
    private let diffusionModelStore = DiffusionModelStore.shared
    
    func prepare() async {
        let urls = await diffusionModelStore.urls()
        availableModels = urls.map { DiffusionModel(url: $0) }
        if
            let initialConfiguration,
            let model = availableModels.first(where: { $0.id == initialConfiguration.modelID }) {
            selectedModel = model
        } else if let model = availableModels.first {
            selectedModel = model
        }
        if let initialConfiguration {
            selectedComputeUnits = initialConfiguration.computeUnits
            selectedControlNets = .init(initialConfiguration.controlNets)
        }
    }
    
    func toggleSelection(controlNet: String) {
        if selectedControlNets.contains(controlNet) {
            selectedControlNets.remove(controlNet)
        } else {
            selectedControlNets.insert(controlNet)
        }
    }
    
    func openModelDirectory() {
        openDirectory(url: diffusionModelStore.baseURL)
    }
    
    func openSite() {
        openURL(.init(string: "https://huggingface.co/coreml")!)
    }
}
