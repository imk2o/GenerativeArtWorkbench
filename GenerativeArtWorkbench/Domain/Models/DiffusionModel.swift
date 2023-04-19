//
//  DiffusionModel.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/22.
//

import Foundation

struct DiffusionModel: Identifiable {
    var id : String { name }
    let name: String
    let url: URL
    let controlNets: [String]
    
    init(url: URL) {
        self.name = url.lastPathComponent
        self.url = url
        self.controlNets = Self.controlNetFiles(for: url)
    }
    
    private init(name: String, url: URL) {
        self.name = name
        self.url = url
        self.controlNets = []
    }
    
    static let empty = DiffusionModel(
        name: "",
        url: URL(string: "https://example.com")!
    )
    
    private static func controlNetFiles(for url: URL) -> [String] {
        guard let fileURLs = (try? FileManager.default.contentsOfDirectory(
            at: url.appendingPathComponent("controlnet"),
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )) else {
            return []
        }
        
        return fileURLs.compactMap { fileURL in
            guard fileURL.pathExtension == "mlmodelc" else { return nil }
            return fileURL.deletingPathExtension().lastPathComponent
        }
    }
}
