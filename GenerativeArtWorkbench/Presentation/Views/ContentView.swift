//
//  ContentView.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/08.
//

import SwiftUI

enum Playground: Hashable {
    case coreImage(CoreImagePlaygroundView.Context)
    case vision
    case diffusion
    case upscaling(UpscalingPlaygroundView.Context)
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
                        ImageDropNavigationLink(
                            title: "Core Image",
                            value: Playground.coreImage(.new)
                        ) { selectedPlayground = .coreImage(.inputImage($0)) }
                        NavigationLink("Vision", value: Playground.vision)
                        NavigationLink("Diffusion", value: Playground.diffusion)
                        ImageDropNavigationLink(
                            title: "Upscaling",
                            value: Playground.upscaling(.new)
                        ) { selectedPlayground = .upscaling(.inputImage($0)) }
                    }
                }
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(240)
            },
            detail: {
                NavigationStack {
                    if let selectedPlayground {
                        switch selectedPlayground {
                        case .coreImage(let context):
                            CoreImagePlaygroundView(context: context)
                        case .diffusion:
                            DiffusionPlaygroundView()
                        case .upscaling(let context):
                            UpscalingPlaygroundView(context: context)
                        case .vision:
                            VisionPlaygroundView()
                        }
                    } else {
                        Text("Select Playground")
                    }
                }
            }
        )
        .navigationSplitViewStyle(.balanced)
    }
    
    private struct ImageDropNavigationLink<P: Hashable>: View {
        let title: String
        let value: P?
        let onDrop: (CGImage) -> Void
        
        @State private var droppedImage: CGImage?

        var body: some View {
            NavigationLink(title, value: value)
                .onDrop(of: [.image], delegate: ImageDropDelegate(image: $droppedImage))
                .onChange(of: droppedImage) { image in
                    if let image {
                        onDrop(image)
                    }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
