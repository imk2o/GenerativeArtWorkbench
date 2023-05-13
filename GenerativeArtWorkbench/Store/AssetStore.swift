//
//  AssetStore.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/30.
//

import Foundation
import CoreGraphics
import Combine

import StewardFoundation

final class AssetStore {
    static let shared = AssetStore()
    private let fileManager = FileManager.default
    private(set) lazy var baseURL = fileManager.documentDirectory
        .appendingPathComponent("/Assets", isDirectory: true)
    
    private var assetsSubject = CurrentValueSubject<[Asset], Never>([])

    private init() {
        try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
        
        load()
    }

    private func load() {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: baseURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return
        }
        
        let assets = urls
            .sorted {
                guard let lhs = $0.creationDate, let rhs = $1.creationDate else { return true }
                return lhs > rhs
            }
            .map(Asset.init)
        assetsSubject.send(assets)
    }
    
    func asset(for id: String) -> Asset? {
        return assetsSubject.value.first { $0.id == id }
    }
    
    func add(image: CGImage, name: String) async throws {
        guard let data = image.pngData() else {
            fatalError("FIXME")
        }

        let id = Self.id(for: .now)
        let fileURL = baseURL.appending(path: "\(name)_\(id).png")
        try data.write(to: fileURL)
        
        var assets = assetsSubject.value
        assets.insert(Asset(url: fileURL), at: 0)
        assetsSubject.send(assets)
    }
    
    private static func id(for creationDate: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = .current
        return dateFormatter.string(from: creationDate)
    }
    
    typealias AnyAsyncPublisher<T> = AsyncPublisher<AnyPublisher<T, Never>>
    func assets() -> AnyAsyncPublisher<[Asset]> {
        return assetsSubject
            .eraseToAnyPublisher()
            .values
    }
}

extension URL {
    var creationDate: Date? {
        try? resourceValues(forKeys: [URLResourceKey.creationDateKey]).creationDate
    }
}
