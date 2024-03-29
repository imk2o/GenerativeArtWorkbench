//
//  CoreImagePlaygroundPresenter.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/26.
//

import SwiftUI
import Observation
import Combine

import StewardFoundation
import StewardUIKit

import CoreImage

extension CIFilter {
    struct InputAttributes: Identifiable {
        var id: String { key }
        let key: String
        let attributes: [String: Any]
        
        var displayName: String { attributes["CIAttributeDisplayName"] as! String }
        var description: String { attributes["CIAttributeDescription"] as! String }
        var type: String { attributes["CIAttributeType"] as! String }
        var klass: String { attributes["CIAttributeClass"] as! String }
        
        func defaultValue<T>(type: T.Type) -> T? { attributes["CIAttributeDefault"] as? T }
        func minValue<T>(type: T.Type) -> T? { attributes["CIAttributeSliderMin"] as? T }
        func maxValue<T>(type: T.Type) -> T? { attributes["CIAttributeSliderMax"] as? T }
    }
    
    func inputAttributes(for key: String) -> InputAttributes? {
        guard let inputAttributes = attributes[key] as? [String: Any] else { return nil }
        return .init(key: key, attributes: inputAttributes)
    }
    
    var inputImage: CIImage? {
        get { safeValue(forKey: kCIInputImageKey) as? CIImage }
        set { setSafeValue(newValue, forKey: kCIInputImageKey) }
    }
}

@Observable
final class CoreImagePlaygroundPresenter {

    enum Context: Hashable {
        case new
        case inputImage(CGImage)
    }
    @ObservationIgnored
    let context: Context

    init(context: Context = .new) {
        self.context = context
    }

    @ObservationIgnored
    private let imageFilterStore = ImageFilterStore.shared
    @ObservationIgnored
    private let ciContext = CIContext()

    private(set) var availableFilters: [ImageFilter.Category: [ImageFilter]] = [:]

    // Input
    var selectedFilter: ImageFilter = .empty {
        didSet {
            // フィルタを変えてもinputImageは継承
            let inputImage = ciFilter?.inputImage
            ciFilter = CIFilter(name: selectedFilter.name)
            ciFilter?.inputImage = inputImage
        }
    }
    private var ciFilter: CIFilter? {
        didSet {
            guard let ciFilter else { return }
            inputAttributes = ciFilter.inputKeys.compactMap {
                ciFilter.inputAttributes(for: $0)
            }
        }
    }
    private(set) var inputAttributes: [CIFilter.InputAttributes] = []
    
    // Option
    var clampedToExtent = true
    var extent: CGRect = .init(x: 0, y: 0, width: 400, height: 400)
    var isLiveUpdateEnabled = true

    // Output
    private(set) var resultImage: CGImage?
    
    func prepare() async {
        do {
            availableFilters = .init(
                grouping: await imageFilterStore.imageFilters(),
                by: { $0.category }
            )
            if
                let blurFilters = availableFilters[.blur],
                let blurFilter = blurFilters.first(where: { $0.name == "CIGaussianBlur" })
            {
                selectedFilter = blurFilter
            }
            
            if
                case .inputImage(let inputImage) = context,
                let attributes = inputAttributes.first(where: { $0.key == kCIInputImageKey })
            {
                setInputImage(inputImage, for: attributes)
            }
        } catch {
            dump(error)
        }
    }
    
    enum InputValueType {
        case number
        case vector
        case color
        case image
        case string
        case matrix
        case unknown(type: String)
    }
    
    func inputValueType(for inputAttributes: CIFilter.InputAttributes) -> InputValueType {
        switch inputAttributes.klass {
        case "NSNumber":
            return .number
        case "CIVector":
            return .vector
        case "CIColor":
            return .color
        case "CIImage":
            return .image
        case "NSString":
            return .string
        case "NSAffineTransform":
            return .matrix
        default:
            return .unknown(type: inputAttributes.klass)
        }
    }

    func inputRange(for attributes: CIFilter.InputAttributes) -> ClosedRange<CGFloat> {
        guard
            let min = attributes.minValue(type: CGFloat.self),
            let max = attributes.maxValue(type: CGFloat.self)
        else {
            return 0...1
        }

        return min...max
    }

    func inputPreferredStep(for attributes: CIFilter.InputAttributes) -> CGFloat {
        if let max = attributes.maxValue(type: CGFloat.self) {
            if max <= 1 {
                return 0.01
            } else if max <= 100 {
                return 0.1
            } else {
                return 1
            }
        }

        return 0
    }

    func inputNumber(for attributes: CIFilter.InputAttributes) -> CGFloat {
        return (ciFilter?.safeValue(forKey: attributes.key) as? CGFloat) ?? 0
    }

    func setInputNumber(_ value: CGFloat, for attributes: CIFilter.InputAttributes) {
        updateInputValue {
            ciFilter?.setSafeValue(value, forKey: attributes.key)
        }
    }

    func inputVector(for attributes: CIFilter.InputAttributes) -> Vector4 {
        guard let ciVector = ciFilter?.safeValue(forKey: attributes.key) as? CIVector else { return .zero }
        return .init(ciVector)
    }

    func setInputVector(_ vector: Vector4, for attributes: CIFilter.InputAttributes) {
        updateInputValue {
            ciFilter?.setSafeValue(CIVector(vector), forKey: attributes.key)
        }
    }
    
    func inputColor(for attributes: CIFilter.InputAttributes) -> ColorRGB {
        guard let ciColor = ciFilter?.safeValue(forKey: attributes.key) as? CIColor else { return .transparent }
        return .init(ciColor)
    }

    func setInputColor(_ color: ColorRGB, for attributes: CIFilter.InputAttributes) {
        updateInputValue {
            ciFilter?.setSafeValue(CIColor(color), forKey: attributes.key)
        }
    }
    
    func inputImage(for attributes: CIFilter.InputAttributes) -> CGImage? {
        guard let ciImage = ciFilter?.safeValue(forKey: attributes.key) as? CIImage else { return nil }
        return ciImage.cgImage
    }

    func setInputImage(_ image: CGImage?, for attributes: CIFilter.InputAttributes) {
        updateInputValue {
            ciFilter?.setSafeValue(image.flatMap(CIImage.init), forKey: attributes.key)
            // 入力画像の大きさをextentに反映
            if
                let image,
                attributes.key == kCIInputImageKey
            {
                extent = .init(x: 0, y: 0, width: image.width, height: image.height)
            }
        }
    }
    
    func inputString(for attributes: CIFilter.InputAttributes) -> String {
        return ciFilter?.safeValue(forKey: attributes.key) as? String ?? ""
    }

    func setInputString(_ string: String, for attributes: CIFilter.InputAttributes) {
        updateInputValue {
            ciFilter?.setSafeValue(string, forKey: attributes.key)
        }
    }

    func inputMatrix(for attributes: CIFilter.InputAttributes) -> Matrix3 {
        guard let transform = ciFilter?.safeValue(forKey: attributes.key) as? CGAffineTransform else { return .identity }
        
        return .init(transform)
    }

    func setInputMatrix(_ matrix: Matrix3, for attributes: CIFilter.InputAttributes) {
        updateInputValue {
            ciFilter?.setSafeValue(CGAffineTransform(matrix), forKey: attributes.key)
        }
    }

    func run() async {
        // clampedToExtent差し込み破壊する場合があるため、コピーを使う
        guard let filter = ciFilter?.copy() as? CIFilter else { return }
        if clampedToExtent {
            filter.inputImage = filter.inputImage?.clampedToExtent()
        }
        guard let outputImage = filter.outputImage else { return }

        do {
            resultImage = ciContext.createCGImage(outputImage, from: extent)
        } catch {
            dump(error)
        }
    }
    
    private func updateInputValue(updater: () -> Void) {
        withMutation(keyPath: \.inputAttributes) {
            updater()
        }
        if isLiveUpdateEnabled {
            Task { await run() }
        }
    }
}
