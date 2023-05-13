//
//  SketchPresenter.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/20.
//

import UIKit
import Combine
import StewardArchitecture

@MainActor
final class SketchPresenter: ObservableObject {
    init() {
        bind()
    }

    // MARK: - Injection

//    @Injected(.someUseCase)
//    private var someUseCase: SomeUseCase

    // MARK: - Binding

//    @Published var text: String = "" {
//        didSet { ... }
//    }

    // MARK: - Output

//    @Published private(set) var item: SomeItem?
//    @Published private(set) var hud: CommonHUD = .none
//    @Published private(set) var failureAlert: CommonFailureAlert?

    // MARK: - Action

//    func load() async {
//        guard !hud.inProgress else { return }
//
//        hud = .loading(true)
//        defer { hud = .loading(false) }
//        do {
//            item = try await someUseCase.item(id: id)
//            failureAlert = nil
//        } catch {
//            guard !Task.isCancelled else { return }
//
//            failureAlert = .init(error: error)
//        }
//    }

    // MARK: - private 

    private func bind() {
    }
}
