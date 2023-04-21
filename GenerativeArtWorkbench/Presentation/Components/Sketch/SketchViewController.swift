//
//  SketchViewController.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/20.
//

import UIKit
import Combine
import StewardArchitecture

extension SketchViewController {
    static func instantiate(
        presenter: SketchPresenter,
        actionHandler: ((SketchViewController.Action) -> Void)? = nil
    ) -> SketchViewController {
        let storyboard = UIStoryboard(name: "Sketch", bundle: nil)
        return storyboard.instantiateInitialViewController {
            SketchViewController(coder: $0, presenter: presenter, actionHandler: actionHandler)
        }!
    }
}

final class SketchViewController: UIViewController {
    enum Action {
        case done(CGImage)
    }

    private init(
        coder: NSCoder,
        presenter: SketchPresenter,
        actionHandler: ((Action) -> Void)?
    ) {
        self.presenter = presenter
        self.actionHandler = actionHandler
        super.init(coder: coder)!
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Subviews

    @IBOutlet private weak var sketchView: SketchView!
    
    // MARK: - Property
    private var presenter: SketchPresenter
    private let actionHandler: ((Action) -> Void)?
    private let tasks = ConcurrencyTaskStore()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle & Setup

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        bind()
//        tasks += Task {
//            await presenter.load()
//        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
// 画面を閉じたときに全てのタスクをキャンセル
// 子VCとして追加・削除する場合など、着脱がある場合は要注意
//        tasks.cancelAll()
    }
    
    func restore(image: CGImage) {
        // Restore once
        guard sketchView.canvasImage.cgImage == nil else { return }
        sketchView.restoreCanvas(with: UIImage(cgImage: image), contentMode: .fit)
    }
    
    private func setup() {
        let whitePen = SketchView.PenTool()
        whitePen.color = .white
        whitePen.lineWidth = 8
        sketchView.currentTool = whitePen
    }

    private func bind() {
        // TDOO: Presenterとのバインディング

//        // HUD
//        presenter.$hud
//            .sink { [unowned self] in
//                handleHUD($0)
//            }
//            .store(in: &cancellables)
//        // FailureAlert
//        presenter.$failureAlert
//            .sink { [unowned self] in
//                handleFailureAlert($0)
//            }
//            .store(in: &cancellables)
    }

    // MARK: Actions

    @IBAction private func done(_ sender: Any) {
        actionHandler?(.done(sketchView.canvasImage.cgImage!))
        dismiss(animated: true)
    }
    
    @IBAction private func cancel(_ sender: Any) {
        dismiss(animated: true)
    }
}
