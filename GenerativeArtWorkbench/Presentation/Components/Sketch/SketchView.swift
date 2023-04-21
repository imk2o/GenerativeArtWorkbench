//
//  SketchView.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/20.
//

import UIKit

/// 手書き入力ビュー。
final class SketchView: UIView {

    /// キャンバスの表示モード。
    enum CanvasContentMode {
        case fill
        case fit
    }

    /// 現在の描画ツール。
    var currentTool: SketchViewTool = PenTool()

    // 現在の描画ツールコマンド。
    private var currentCommand: SketchViewToolCommand?
    // 最新のキャンバス画像
    private(set) var canvasImage: UIImage = .init()
    // 元のキャンバス画像
    private var originalCanvasImage: UIImage = .init()
    // キャンバスの表示モード
    private var canvasContentMode: CanvasContentMode = .fit
    // 表示モードによってキャンバスをビューに配置するための変換パラメータ
    private var canvasTransform: CGAffineTransform = .identity {
        didSet { canvasTransformInverted = canvasTransform.inverted() }
    }
    private var canvasTransformInverted: CGAffineTransform = .identity
    // 操作履歴(Undo用)
    private var commandHistory: [SketchViewToolCommand] = []

    override var bounds: CGRect {
        didSet { correctCanvasTransform() }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    private func setup() {
        // 消しゴムが正しく機能するよう、以下の設定は必須
        backgroundColor = .clear
        isOpaque = false
    }

    /// キャンバスをクリアする。
    /// - Parameters:
    ///   - size: キャンバスの大きさ
    ///   - scale: スケール
    ///   - color: クリアカラー
    ///   - contentMode: 表示モード
    func clearCanvas(size: CGSize, scale: CGFloat = 0, color: UIColor = .clear, contentMode: CanvasContentMode = .fit) {
        let format = UIGraphicsImageRendererFormat.preferred()
        if scale > 0 {
            format.scale = scale
        }

        let clearImage = UIGraphicsImageRenderer(size: size, format: format)
            .image { context in
                color.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
        restoreCanvas(with: clearImage, contentMode: contentMode)
    }

    /// 指定画像でキャンバスを復元する。
    /// - Parameters:
    ///   - image: 復元用画像
    ///   - contentMode: 表示モード
    func restoreCanvas(with image: UIImage, contentMode: CanvasContentMode) {
        canvasImage = image
        originalCanvasImage = image
        canvasContentMode = contentMode
        commandHistory = .init()
        correctCanvasTransform()

        setNeedsDisplay()
    }

    /// Undo可能であればtrueを返す。
    func canUndo() -> Bool {
        !commandHistory.isEmpty
    }

    /// Undoする。
    func undo() {
        guard canUndo() else {
            return
        }

        // 最新の操作履歴を除き、元のキャンバス画像に対して全操作履歴を反映した画像に差し替える
        // (TODO: 履歴が多いと復元負荷が高いため、ストレージに適時残したスナップショットを参照する仕組みがあるといいかも)
        commandHistory.removeLast()
        canvasImage = originalCanvasImage.render(commands: commandHistory)
        setNeedsDisplay()
    }

    // キャンバスを、現在のビューと表示モードに合わせて配置するための変換パラメータを更新する
    private func correctCanvasTransform() {
        canvasTransform = {
            switch canvasContentMode {
            case .fill:
                let scale = canvasImage.size.scaleForAspectFill(targetSize: bounds.size)
                let tx = (bounds.size.width - (canvasImage.size.width * scale)) / 2
                let ty = (bounds.size.height - (canvasImage.size.height * scale)) / 2
                return CGAffineTransform(translationX: tx, y: ty)
                    .scaledBy(x: scale, y: scale)
            case .fit:
                let scale = canvasImage.size.scaleForAspectFit(targetSize: bounds.size)
                let tx = (bounds.size.width - (canvasImage.size.width * scale)) / 2
                let ty = (bounds.size.height - (canvasImage.size.height * scale)) / 2
                return CGAffineTransform(translationX: tx, y: ty)
                    .scaledBy(x: scale, y: scale)
            }
        }()

        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        context.saveGState()
        context.concatenate(canvasTransform)

        canvasImage.draw(at: .zero)
        // 追跡中のストロークを描画
        context.clip(to: CGRect(origin: .zero, size: canvasImage.size))
        currentCommand?.render(context: context)

        context.restoreGState()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard let touch = touches.first else {
            return
        }
        let canvasLocation = touch.location(in: self).applying(canvasTransformInverted)

//        sketchViewDelegate?.drawView?(self, willBeginDrawUsingTool: currentTool! as AnyObject)

        // touchesBegan〜touchesEnded間のストロークを追跡・描画するためのコマンドオブジェクトを生成
        let command = currentTool.createCommand()
        command.begin(point: canvasLocation)
        currentCommand = command
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        guard
            let touch = touches.first,
            let currentCommand = self.currentCommand
        else {
            return
        }
        let canvasLocation = touch.location(in: self).applying(canvasTransformInverted)

        // ストロークの追跡ポイントを追加し、表示を更新
        let boundary = currentCommand
            .track(point: canvasLocation)
            .applying(canvasTransform)
        setNeedsDisplay(boundary)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        guard
            let touch = touches.first,
            let currentCommand = self.currentCommand
        else {
            return
        }
        let canvasLocation = touch.location(in: self).applying(canvasTransformInverted)

        // ストロークの追跡を終了し、キャンバスに反映
        currentCommand.end(point: canvasLocation)
        commitCommand()
//        sketchViewDelegate?.drawView?(self, willBeginDrawUsingTool: currentTool! as AnyObject)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        cancelCommand()
    }

    private func commitCommand() {
        guard let currentCommand = self.currentCommand else {
            return
        }

        // 最新のキャンバスにストロークを反映した画像を生成し、操作履歴に加える
        canvasImage = canvasImage.render(commands: [currentCommand])
        commandHistory.append(currentCommand)
        self.currentCommand = nil

        setNeedsDisplay()
    }

    private func cancelCommand() {
        guard let currentCommand = self.currentCommand else {
            return
        }

        currentCommand.cancel()
        self.currentCommand = nil

        setNeedsDisplay()
    }
}

private extension UIImage {
    /// 自身にcommandsで指定された描画コマンドを適用する
    func render(commands: [SketchViewToolCommand]) -> UIImage {
        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = scale

        return UIGraphicsImageRenderer(size: size, format: format)
            .image { context in
                draw(at: .zero)
                let cgContext = context.cgContext
                commands.forEach { $0.render(context: cgContext) }
            }
    }
}

private extension CGSize {
    /// アスペクト比。
    var aspectRatio: CGFloat { self.width / self.height }

    /// targateSizeにAspect Fitで合わせる場合のスケーリング率を求める。
    func scaleForAspectFit(targetSize: CGSize) -> CGFloat {
        return self.aspectRatio > targetSize.aspectRatio ?
            targetSize.width / self.width :
            targetSize.height / self.height
    }

    /// targateSizeにAspect Fillで合わせる場合のスケーリング率を求める。
    func scaleForAspectFill(targetSize: CGSize) -> CGFloat {
        return self.aspectRatio > targetSize.aspectRatio ?
            targetSize.height / self.height :
            targetSize.width / self.width
    }
}

import UIKit

// MARK: - Protocols

/// SketchViewの描画ツール。
protocol SketchViewTool: AnyObject {
    /// 描画コマンド・オブジェクトを生成する。
    func createCommand() -> SketchViewToolCommand
}

/// SketchViewの描画コマンド。
/// touchesBegan〜touchesEnded間の操作をトラッキングし、コンテキストに描画する機能を提供する。
protocol SketchViewToolCommand: AnyObject {
    /// 操作の追跡を開始する。
    /// touchesBegan()の際に呼び出される。
    /// - Parameter point: タッチされた座標
    func begin(point: CGPoint)

    /// 操作を追跡する。
    /// touchesMoved()の際に呼び出される。
    /// - Parameter point: タッチされた座標
    @discardableResult
    func track(point: CGPoint) -> CGRect

    /// 操作の追跡を終了する。
    /// touchesEnded()の際に呼び出される。
    /// - Parameter point: タッチされた座標
    @discardableResult
    func end(point: CGPoint) -> CGRect

    /// 操作の追跡をキャンセルする。
    /// touchesCancelled()の際に呼び出される。
    func cancel()

    /// 追跡結果をもとに描画を行う。
    /// - Parameter context: 描画コンテキスト
    func render(context: CGContext)
}

/// SketchViewのBezierパス描画用コマンド。
protocol SketchViewToolPathCommand: SketchViewToolCommand {
    var path: UIBezierPath { get }
    var beforeLastPoint: CGPoint { get set }
    var lastPoint: CGPoint { get set }
}

extension SketchViewToolPathCommand {
    func begin(point: CGPoint) {
        lastPoint = point
        beforeLastPoint = point
    }

    @discardableResult
    func track(point: CGPoint) -> CGRect {
        let mp1 = middlePoint(lastPoint, beforeLastPoint)
        let mp2 = middlePoint(point, lastPoint)

        let subpath = UIBezierPath()
        subpath.move(to: mp1)
        subpath.addQuadCurve(to: mp2, controlPoint: lastPoint)
        path.append(subpath)

        let width = path.lineWidth
        let boundary = subpath.bounds.inset(by: UIEdgeInsets(top: -width, left: -width, bottom: -width, right: -width))

        beforeLastPoint = lastPoint
        lastPoint = point

        return boundary
    }

    private func middlePoint(_ p1: CGPoint,_ p2: CGPoint) -> CGPoint {
        return CGPoint(
            x: (p1.x + p2.x) / 2,
            y: (p1.y + p2.y) / 2
        )
    }

    @discardableResult
    func end(point: CGPoint) -> CGRect {
        if point == lastPoint && point == beforeLastPoint {
            // タッチして、動かずに離した場合は点描する
            let subpath = UIBezierPath()
            subpath.move(to: point)
            subpath.addLine(to: point)
            path.append(subpath)
        }

        let width = path.lineWidth
        let boundary = path.bounds.inset(by: UIEdgeInsets(top: -width, left: -width, bottom: -width, right: -width))

        return boundary
    }
}

// MARK: - Concrete tools

extension SketchView {
    /// ペン描画ツール。
    final class PenTool: SketchViewTool {
        /// 線の幅。
        var lineWidth: CGFloat = 1
        /// 線の色。
        var color: UIColor = .black

        func createCommand() -> SketchViewToolCommand {
            Command(lineWidth: lineWidth, color: color)
        }

        private class Command: SketchViewToolPathCommand {
            let path = UIBezierPath()
            var lastPoint: CGPoint = .zero
            var beforeLastPoint: CGPoint = .zero
            let color: UIColor

            init(lineWidth: CGFloat, color: UIColor) {
                path.lineWidth = lineWidth
                path.lineCapStyle = .round
                self.color = color
            }

            func cancel() {
            }

            func render(context: CGContext) {
                color.setStroke()
                path.stroke()
            }
        }
    }

    /// 消しゴムツール。
    final class EraserTool: SketchViewTool {
        /// 消しゴムの幅。
        var lineWidth: CGFloat = 1

        func createCommand() -> SketchViewToolCommand {
            Command(lineWidth: lineWidth)
        }

        private class Command: SketchViewToolPathCommand {
            let path = UIBezierPath()
            var lastPoint: CGPoint = .zero
            var beforeLastPoint: CGPoint = .zero

            init(lineWidth: CGFloat) {
                path.lineWidth = lineWidth
                path.lineCapStyle = .round
            }

            func cancel() {
            }

            func render(context: CGContext) {
                context.setBlendMode(.clear)
                path.stroke()
            }
        }
    }
}

