//
//  DiffusionHistory.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/22.
//

import Foundation

struct DiffusionHistory: Identifiable, Codable {
    let id: String
    let creationDate: Date
    let modelID: String
    struct Request: Codable {
        let seed: UInt32
        let prompt: String
        let negativePrompt: String
        let startingImageURL: URL?
        let startingImageStrength: Float
        let stepCount: Int
        let guidanceScale: Float
        enum Scheduler: String, Codable {
            case pndm = "PNDM"
            case dpmSolverMultistep = "DPM-Solver++"
        }
        let scheduler: Scheduler

        struct Configuration {
            let id: String
            let baseURL: URL
        }
    }
    let request: Request
    let resultImageURL: URL

    init(creationDate: Date = .now, modelID: String, request: DiffusionRequest, baseURL: URL) {
        self.id = Self.id(for: creationDate)
        self.creationDate = creationDate
        self.modelID = modelID
        self.request = .init(request: request, configuration: .init(id: id, baseURL: baseURL))
        self.resultImageURL = Self.resultImageURL(id: id, baseURL: baseURL)
    }

    private static func id(for creationDate: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.timeZone = .current
        return dateFormatter.string(from: creationDate)
    }
    
    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case id
        case creationDate
        case modelID
        case request
        case resultImageURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let baseURL = decoder.userInfo[.baseURLUserInfoKey] as! URL

        self.id = try container.decode(String.self, forKey: .id)
        self.creationDate = try container.decode(Date.self, forKey: .creationDate)
        self.modelID = try container.decode(String.self, forKey: .modelID)
        self.request = try container.decode(
            Request.self, forKey: .request,
            configuration: Request.Configuration(id: id, baseURL: baseURL)
        )

        self.resultImageURL = Self.resultImageURL(id: id, baseURL: baseURL)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let baseURL = encoder.userInfo[.baseURLUserInfoKey] as! URL

        try container.encode(id, forKey: .id)
        try container.encode(creationDate, forKey: .creationDate)
        try container.encode(modelID, forKey: .modelID)
        try container.encode(
            request, forKey: .request,
            configuration: Request.Configuration(id: id, baseURL: baseURL)
        )
    }
    
    func resultImageURL(for baseURL: URL) -> URL {
        return Self.resultImageURL(id: id, baseURL: baseURL)
    }
    
    static func resultImageURL(id: ID, baseURL: URL) -> URL {
        return baseURL.appendingPathComponent("\(id).result.png")
    }
}

extension CodingUserInfoKey {
    static let baseURLUserInfoKey = CodingUserInfoKey(rawValue: "baseURL")!
}

extension DiffusionHistory.Request: CodableWithConfiguration {
    private static func startingImageURL(for configuration: Configuration) -> URL {
        return configuration.baseURL.appendingPathComponent("\(configuration.id).starting.png")
    }

    private enum CodingKeys: String, CodingKey {
        case seed
        case prompt
        case negativePrompt
        case startingImageURL
        case startingImageStrength
        case stepCount
        case guidanceScale
        case scheduler
    }

    init(from decoder: Decoder, configuration: Configuration) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.seed = try container.decode(UInt32.self, forKey: .seed)
        self.prompt = try container.decode(String.self, forKey: .prompt)
        self.negativePrompt = try container.decode(String.self, forKey: .negativePrompt)
        self.startingImageURL = Self.startingImageURL(for: configuration)
        self.startingImageStrength = try container.decode(Float.self, forKey: .startingImageStrength)
        self.stepCount = try container.decode(Int.self, forKey: .stepCount)
        self.guidanceScale = try container.decode(Float.self, forKey: .guidanceScale)
        self.scheduler = try container.decode(Scheduler.self, forKey: .scheduler)
    }

    func encode(to encoder: Encoder, configuration: Configuration) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(seed, forKey: .seed)
        try container.encode(prompt, forKey: .prompt)
        try container.encode(negativePrompt, forKey: .negativePrompt)
        try container.encode(startingImageStrength, forKey: .startingImageStrength)
        try container.encode(stepCount, forKey: .stepCount)
        try container.encode(guidanceScale, forKey: .guidanceScale)
        try container.encode(scheduler, forKey: .scheduler)
    }

    fileprivate init(request: DiffusionRequest, configuration: Configuration) {
        self.seed = request.seed
        self.prompt = request.prompt
        self.negativePrompt = request.negativePrompt
        self.startingImageURL = Self.startingImageURL(for: configuration)
        self.startingImageStrength = request.startingImageStrength
        self.stepCount = request.stepCount
        self.guidanceScale = request.guidanceScale
        self.scheduler = .init(request.scheduler)
    }
}

import enum StableDiffusion.StableDiffusionScheduler
extension DiffusionHistory.Request.Scheduler {
    fileprivate init(_ scheduler: StableDiffusionScheduler) {
        switch scheduler {
        case .pndmScheduler:
            self = .pndm
        case .dpmSolverMultistepScheduler:
            self = .dpmSolverMultistep
        }
    }
}
