//
//  DiffusionModelStore.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/19.
//

import Foundation

import StewardFoundation

final class DiffusionModelStore {
    static let shared = DiffusionModelStore()
    private let fileManager = FileManager.default
    private(set) lazy var baseURL = fileManager.documentDirectory
        .appendingPathComponent("/DiffusionModels", isDirectory: true)
    
    private init() {
        try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }
    
    func urls() async -> [URL] {
        return (try? fileManager.contentsOfDirectory(
            at: baseURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )) ?? []
    }
    
    func models() async -> [DiffusionModel] {
        return await urls().map(DiffusionModel.init)
    }
    
    func model(for id: DiffusionModel.ID) async -> DiffusionModel? {
        return await models().first { $0.id == id }
    }

    func openDirectory() {
        
    }
}
