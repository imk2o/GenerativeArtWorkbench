//
//  ScriptView.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/31.
//

import SwiftUI

struct ScriptView: View {
    @StateObject private var presenter = ScriptPresenter()
    
    var body: some View {
        VStack {
            HStack {
                editorView()
                Divider()
                logView()
                    .frame(width: 400)
            }
            errorView()
                .frame(height: 120)
        }
        .navigationTitle("Script")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(
                    action: {
                        Task { await presenter.run() }
                    },
                    label: {
                        Image(systemName: "play.fill")
                    }
                )
            }
        }
        .toolbarRole(.editor)
        .onAppear { Task { await presenter.prepare() } }
    }
    
    private func editorView() -> some View {
        CodeEditor(code: $presenter.code)
    }
    
    private func logView() -> some View {
        List {
            ForEach(presenter.logs.indices, id: \.self) { index in
                switch presenter.logs[index] {
                case .string(let string):
                    Text(string)
                case .image(let image):
                    HStack {
                        InteractiveImage(image, title: "image") { imageView in
                            imageView
                                .resizable()
                                .scaledToFit()
                        }
                        .frame(width: 80, height: 80)
                        Text("\(image.width) x \(image.height)")
                    }
                }
            }
        }
    }
    
    private func errorView() -> some View {
        Text(presenter.error)
    }
}
