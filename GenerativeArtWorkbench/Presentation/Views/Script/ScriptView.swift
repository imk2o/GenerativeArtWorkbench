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
        TextEditor(text: $presenter.code)
    }
    
    private func logView() -> some View {
        List {
            ForEach(presenter.logs.indices, id: \.self) { index in
                switch presenter.logs[index] {
                case .string(let string):
                    Text(string)
                case .image(let image):
                    Image(image, scale: 1, label: Text(""))
                        .resizable()
                        .frame(width: 200, height: 200)
                }
            }
        }
    }
    
    private func errorView() -> some View {
        Text(presenter.error)
    }
}
