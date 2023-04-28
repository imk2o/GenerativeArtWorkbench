//
//  CoreImagePlaygroundPresenter.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/26.
//

import SwiftUI
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

@MainActor
final class CoreImagePlaygroundPresenter: ObservableObject {

    enum Context: Hashable {
        case new
        case inputImage(CGImage)
    }
    let context: Context

    init(context: Context = .new) {
        self.context = context
    }

    private let ciContext = CIContext()
    
    @Published private(set) var availableFilters: [String] = [
        "CIGaussianBlur",
        "CIBoxBlur",
        "CISepiaTone",
        "CIVignette",
        "CIBumpDistortion",
        "CIMultiplyBlendMode",
        "CILinearGradient"
    ]
    @Published var selectedFilter: String = "" {
        didSet {
            // フィルタを変えてもinputImageは継承
            let inputImage = ciFilter?.inputImage
            ciFilter = CIFilter(name: selectedFilter)
            ciFilter?.inputImage = inputImage
        }
    }
    @Published private var ciFilter: CIFilter? {
        didSet {
            guard let ciFilter else { return }
            inputAttributes = ciFilter.inputKeys.compactMap {
                ciFilter.inputAttributes(for: $0)
            }
        }
    }
    @Published private(set) var inputAttributes: [CIFilter.InputAttributes] = []
    
    @Published private(set) var resultImage: CGImage?

    func prepare() async {
        do {
            selectedFilter = availableFilters[0]
            
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
    }
    
    func inputValueType(for inputAttributes: CIFilter.InputAttributes) -> InputValueType? {
        switch inputAttributes.klass {
        case "NSNumber":
            return .number
        case "CIVector":
            return .vector
        case "CIColor":
            return .color
        case "CIImage":
            return .image
        default:
            return nil
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

    func inputNumber(for key: String) -> CGFloat {
        return (ciFilter?.safeValue(forKey: key) as? CGFloat) ?? 0
    }

    func setInputNumber(_ value: CGFloat, for key: String) {
        objectWillChange.send()
        ciFilter?.setSafeValue(value, forKey: key)
    }

    func inputNumberBinding(for key: String) -> Binding<CGFloat> {
        return .init(
            get: { [self] in inputNumber(for: key) },
            set: { [self] in setInputNumber($0, for: key) }
        )
    }

    func inputVector(for attributes: CIFilter.InputAttributes) -> Vector4 {
        guard let ciVector = ciFilter?.safeValue(forKey: attributes.key) as? CIVector else { return .zero }
        return .init(ciVector)
    }

    func setInputVector(_ vector: Vector4, for attributes: CIFilter.InputAttributes) {
        objectWillChange.send()
        ciFilter?.setSafeValue(CIVector(vector), forKey: attributes.key)
    }
    
    func inputVectorBinding(for attributes: CIFilter.InputAttributes) -> Binding<Vector4> {
        return .init(
            get: { [self] in inputVector(for: attributes) },
            set: { [self] in setInputVector($0, for: attributes) }
        )
    }

    func inputColor(for attributes: CIFilter.InputAttributes) -> ColorRGB {
        guard let ciColor = ciFilter?.safeValue(forKey: attributes.key) as? CIColor else { return .transparent }
        return .init(ciColor)
    }

    func setInputColor(_ color: ColorRGB, for attributes: CIFilter.InputAttributes) {
        objectWillChange.send()
        ciFilter?.setSafeValue(CIColor(color), forKey: attributes.key)
    }
    
    func inputColorBinding(for attributes: CIFilter.InputAttributes) -> Binding<ColorRGB> {
        return .init(
            get: { [self] in inputColor(for: attributes) },
            set: { [self] in setInputColor($0, for: attributes) }
        )
    }

    func inputImage(for attributes: CIFilter.InputAttributes) -> CGImage? {
        guard let ciImage = ciFilter?.safeValue(forKey: attributes.key) as? CIImage else { return nil }
        return ciImage.cgImage
    }

    func setInputImage(_ image: CGImage?, for attributes: CIFilter.InputAttributes) {
        objectWillChange.send()
        ciFilter?.setSafeValue(image.flatMap(CIImage.init), forKey: attributes.key)
    }
    
    func inputImageBinding(for attributes: CIFilter.InputAttributes) -> Binding<CGImage?> {
        return .init(
            get: { [self] in inputImage(for: attributes) },
            set: { [self] in setInputImage($0, for: attributes) }
        )
    }

    func run() async {
        guard
            let ciFilter,
            let outputImage = ciFilter.outputImage
        else { return }

        do {
            let rect = ciFilter.inputImage?.extent ?? CGRect(x: 0, y: 0, width: 512, height: 512)
            resultImage = ciContext.createCGImage(outputImage, from: rect)
        } catch {
            dump(error)
        }
    }
}
