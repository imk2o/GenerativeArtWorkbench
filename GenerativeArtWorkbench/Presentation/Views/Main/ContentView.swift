//
//  ContentView.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/08.
//

import SwiftUI

enum Playground: Hashable {
    case script
    case coreImage(CoreImagePlaygroundView.Context)
    case vision(VisionPlaygroundView.Context)
    case diffusion
}

struct ContentView: View {
    @State private var selectedPlayground: Playground?
    @State private var droppedImage: UIImage?

    var body: some View {
        NavigationSplitView(
            sidebar: {
                VStack {
                    List(selection: $selectedPlayground) {
                        Section("Scripts") {
                            NavigationLink("Script", value: Playground.script)
                        }
                        Section("Playgrounds") {
                            ImageDropNavigationLink(
                                title: "Core Image",
                                value: Playground.coreImage(.new)
                            ) {
                                selectedPlayground = .coreImage(.inputImage($0))
                            }
                            ImageDropNavigationLink(
                                title: "Vision",
                                value: Playground.vision(.new)
                            ) {
                                selectedPlayground = .vision(.inputImage($0))
                            }
                            NavigationLink("Diffusion", value: Playground.diffusion)
                        }
                    }
                    .listStyle(.sidebar)
                    AssetsView()
                }
                .navigationSplitViewColumnWidth(240)
            },
            detail: {
                NavigationStack {
                    if let selectedPlayground {
                        switch selectedPlayground {
                        case .script:
                            ScriptView()
                        case .coreImage(let context):
                            CoreImagePlaygroundView(context: context)
                        case .diffusion:
                            DiffusionPlaygroundView()
                        case .vision(let context):
                            VisionPlaygroundView(context: context)
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
                .onChange(of: droppedImage) { _, image in
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
