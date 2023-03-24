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
    
    init(url: URL) {
        self.name = url.lastPathComponent
        self.url = url
    }
    
    private init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
    
    static let empty = DiffusionModel(
        name: "",
        url: URL(string: "https://example.com")!
    )
}
