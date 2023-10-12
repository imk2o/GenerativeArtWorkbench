//
//  AssetsPresenter.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/30.
//

import SwiftUI
import Observation
import UniformTypeIdentifiers

import StewardArchitecture

@Observable
final class AssetsPresenter {
    private(set) var assets: [Asset] = []
    
    @ObservationIgnored
    private let assetStore = AssetStore.shared
    
    func listen() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [self] in
                for await assets in assetStore.assets() {
                    self.assets = assets
                }
            }
            // TODO: 監視対象があればgroup.addTaskする
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
