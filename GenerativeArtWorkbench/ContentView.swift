//
//  ContentView.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/08.
//

import SwiftUI

enum Playground: String, Identifiable, CaseIterable {
    case diffusion

    var id: String { rawValue }

    var title: String {
        switch self {
        case .diffusion: return "Diffusion"
        }
    }
}

struct ContentView: View {
    @State private var selectedCategory: Category?
    
    var body: some View {
        NavigationSplitView(
            sidebar: {
                List {
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
                    DiffusionPlaygroundView()
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
