//
//  VisionModelStore.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/24.
//

import Foundation

import StewardFoundation

final class VisionModelStore {
    static let shared = VisionModelStore()
    private let fileManager = FileManager.default
    private(set) lazy var baseURL = fileManager.documentDirectory
        .appendingPathComponent("/VisionModels", isDirectory: true)
    
    private init() {
        try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }
    
    func models() async -> [VisionModel] {
        return await urls().map(VisionModel.init)
    }
    
    func model(for id: VisionModel.ID) async -> VisionModel? {
        return await models().first { $0.id == id }
    }
    
    private func urls() async -> [URL] {
        return (try? fileManager.contentsOfDirectory(
            at: baseURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )) ?? []
    }
}
