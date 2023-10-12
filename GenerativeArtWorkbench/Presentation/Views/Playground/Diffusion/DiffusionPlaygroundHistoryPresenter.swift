//
//  DiffusionPlaygroundHistoryPresenter.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/20.
//

import SwiftUI
import Observation

import StewardFoundation
import StewardUIKit

@Observable
final class DiffusionPlaygroundHistoryPresenter {
    private(set) var histories: [DiffusionHistory] = []

    func prepare() async {
        Task.detached {
            for await histories in DiffusionHistoryStore.shared.histories() {
                Task { @MainActor in
                    self.histories = histories
                }
            }
        }
    }
}
