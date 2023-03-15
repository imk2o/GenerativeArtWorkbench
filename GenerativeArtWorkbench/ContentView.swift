//
//  ContentView.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/08.
//

import SwiftUI

enum Playground: Hashable {
    case diffusion
    case upscaling(inputImage: CGImage?)
}

struct ContentView: View {
    @State private var selectedPlayground: Playground?
    @State private var droppedImage: UIImage?

    var body: some View {
        NavigationSplitView(
            sidebar: {
                List(selection: $selectedPlayground) {
                    Section("Scripts") {
                        Text("FIXME")
                    }
                    Section("Playgrounds") {
                        NavigationLink("Diffusion", value: Playground.diffusion)
                        NavigationLink("Upscaling", value: Playground.upscaling(inputImage: nil))
                            .onDrop(of: [.image], delegate: ImageDropDelegate(image: $droppedImage))
                            .onChange(of: droppedImage) { image in
                                if let image {
                                    selectedPlayground = .upscaling(inputImage: image.cgImage)
                                }
                            }
                    }
                }
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(240)
            },
            detail: {
                NavigationStack {
                    if let selectedPlayground {
                        switch selectedPlayground {
                        case .diffusion:
                            DiffusionPlaygroundView()
                        case .upscaling(let image):
                            UpscalingPlaygroundView(inputImage: image)
                        }
                    } else {
                        Text("Select Playground")
                    }
                }
            }
        )
        .navigationSplitViewStyle(.balanced)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
