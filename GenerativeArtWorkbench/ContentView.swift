//
//  ContentView.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/08.
//

import SwiftUI

enum Playground: String, Identifiable, CaseIterable {
    case diffusion
    case upscaling
    
    var id: String { rawValue }

    var title: String {
        switch self {
        case .diffusion: return "Diffusion"
        case .upscaling: return "Upscaling"
        }
    }
}

struct ContentView: View {
    @State private var selectedPlayground: Playground?
    
    var body: some View {
        NavigationSplitView(
            sidebar: {
                List(selection: $selectedPlayground) {
                    Section("Scripts") {
                        Text("FIXME")
                    }
                    Section("Playgrounds") {
                        ForEach(Playground.allCases) { playground in
                            NavigationLink(playground.title, value: playground)
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
                        case .upscaling:
                            UpscalingPlaygroundView()
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
