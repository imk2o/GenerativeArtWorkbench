//
//  AssetsPresenter.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/30.
//

import SwiftUI
import UniformTypeIdentifiers

import StewardArchitecture

@MainActor
final class AssetsPresenter: ObservableObject {
    @Published private(set) var assets: [Asset] = []
    
    private let assetStore = AssetStore.shared
    private let tasks = ConcurrencyTaskStore()
    
    deinit {
        tasks.cancelAll()
    }
    
    func prepare() async {
        tasks += Task.detached { [weak self] in
            guard let assetStore = self?.assetStore else { return }
            for await assets in assetStore.assets() {
                Task { @MainActor [weak self] in
                    self?.assets = assets
                }
            }
        }
    }
    
    func add(image: CGImage) async {
        do {
            try await assetStore.add(image: image, name: "image")
        } catch {
            dump(error)
        }
    }
    
    func dragItem(for asset: Asset) -> NSItemProvider {
        guard let pngData = try? Data(contentsOf: asset.url) else { return .init() }

        return .init(
            item: pngData as NSSecureCoding,
            typeIdentifier: UTType.png.identifier
        )
    }
    
    func browseAssetsFolder() async {
        openDirectory(url: assetStore.baseURL)
    }
}
