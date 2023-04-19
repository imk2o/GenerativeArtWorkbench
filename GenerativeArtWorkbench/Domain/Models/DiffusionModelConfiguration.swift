//
//  DiffusionModelConfiguration.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/14.
//

import Foundation

struct DiffusionModelConfiguration: Codable {
    let modelID: String
    let controlNets: [String]
    enum ComputeUnits: String, Codable {
        case cpu
        case cpuGPU = "cpu_gpu"
        case cpuNE = "cpu_ne"
        case all
    }
    let computeUnits: ComputeUnits
    static let empty = DiffusionModelConfiguration(
        modelID: "",
        controlNets: [],
        computeUnits: .all
    )
}
