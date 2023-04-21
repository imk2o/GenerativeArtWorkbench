//
//  Sketch.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/20.
//

import SwiftUI

struct Sketch: UIViewControllerRepresentable {
    struct Item: Equatable {
        var image: CGImage
        private let id = UUID()
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.id == rhs.id
        }
    }
    @Binding var item: Item

    func updateUIViewController(_ sketchViewController: SketchViewController, context: Context) {
        sketchViewController.restore(image: item.image)
    }

    func makeUIViewController(context: Context) -> SketchViewController {
        return .instantiate(presenter: .init()) { action in
            switch action {
            case .done(let image):
                self.item = .init(image: image)
            }
        }
    }
}

extension View {
    func sketch(
        isPresented: Binding<Bool>,
        item: Binding<Sketch.Item>
    ) -> some View {
        return self
            .sheet(isPresented: isPresented) {
                Sketch(item: item)
            }
    }
}
