//
//  Asset.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/30.
//

import Foundation

struct Asset: Identifiable {
    var id: String { name }
    let name: String
    let url: URL
    enum FileType {
        case image
    }
    let type: FileType
    
    init(url: URL) {
        self.name = url.deletingPathExtension().lastPathComponent
        self.url = url
        self.type = .image	// FIXME
    }
    
    private init(name: String, url: URL, type: FileType) {
        self.name = name
        self.url = url
        self.type = type
    }

    static let empty = Asset(
        name: "",
        url: URL(string: "https://example.com")!,
        type: .image
    )
}
