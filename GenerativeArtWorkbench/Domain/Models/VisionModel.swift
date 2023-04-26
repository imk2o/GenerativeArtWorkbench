//
//  VisionModel.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/24.
//

import Foundation

struct VisionModel: Identifiable {
    var id: String { name }
    let name: String
    let url: URL
    
    init(url: URL) {
        self.name = url.deletingPathExtension().lastPathComponent
        self.url = url
    }
    
    private init(name: String, url: URL) {
        self.name = name
        self.url = url
    }

    static let empty = VisionModel(
        name: "",
        url: URL(string: "https://example.com")!
    )
}
