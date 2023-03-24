//
//  DiffusionHistoryStore.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/20.
//

import Foundation
import Combine
import UIKit

import StewardFoundation

final class DiffusionHistoryStore {
    static let shared = DiffusionHistoryStore()
    
    private let fileManager = FileManager.default
    
    private(set) lazy var baseURL = fileManager.documentDirectory
        .appendingPathComponent("/DiffusionHistories", isDirectory: true)
    private(set) lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        // https://developer.apple.com/library/archive/qa/qa1480/_index.html
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
    private(set) lazy var jsonEncoder: JSONEncoder = {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        jsonEncoder.dateEncodingStrategy = .formatted(dateFormatter)
        //jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
        jsonEncoder.userInfo[.baseURLUserInfoKey] = baseURL
        return jsonEncoder
    }()
    private(set) lazy var jsonDecoder: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
        //jsonDecoder.keyDecodingStrategy = .convertToSnakeCase
        jsonDecoder.userInfo[.baseURLUserInfoKey] = baseURL
        return jsonDecoder
    }()

    private var historiesSubject = CurrentValueSubject<[DiffusionHistory], Never>([])

    private init() {
        try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)

        Task { await load() }
    }

    private func load() async {
        guard let fileURLs = try? fileManager.contentsOfDirectory(
            at: baseURL, includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return
        }
        
        let histories = fileURLs
            .filter { $0.pathExtension == "json" }
            .compactMap { fileURL -> DiffusionHistory? in
                guard
                    let data = try? Data(contentsOf: fileURL),
                    let history = try? jsonDecoder.decode(DiffusionHistory.self, from: data)
                else {
                    return nil
                }
                
                return history
            }
            .sorted { $0.creationDate > $1.creationDate }
        historiesSubject.send(histories)
    }
    
    func add(
        resultImage: CGImage,
        request: DiffusionRequest,
        model: DiffusionModel
    ) async throws {
        let history = DiffusionHistory(modelID: model.id, request: request, baseURL: baseURL)
        
        let historyURL = baseURL.appendingPathComponent("\(history.id).json")
        let jsonData = try jsonEncoder.encode(history)
        try jsonData.write(to: historyURL)
        // 結果画像の保存
        if let resultImageData = UIImage(cgImage: resultImage).pngData() {
            try resultImageData.write(to: history.resultImageURL)
        }
        // 開始画像の保存
        if
            let startingImage = request.startingImage,
            let startingImageURL = history.request.startingImageURL,
            let startingImageData = UIImage(cgImage: startingImage).pngData() {
            try startingImageData.write(to: startingImageURL)
        }

        var histories = historiesSubject.value
        histories.insert(history, at: 0)
        historiesSubject.send(histories)
    }

    typealias AnyAsyncPublisher<T> = AsyncPublisher<AnyPublisher<T, Never>>
    func histories() -> AnyAsyncPublisher<[DiffusionHistory]> {
        return historiesSubject
            .eraseToAnyPublisher()
            .values
    }
}
