//
//  DiffusionPlaygroundHistoryView.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/03/24.
//

import SwiftUI

struct DiffusionPlaygroundHistoryView: View {
    private(set) var onTap: (DiffusionHistory) -> Void
    
    @StateObject private var presenter = DiffusionPlaygroundHistoryPresenter()
    
    var body: some View {
        List {
            ForEach(presenter.histories) { history in
                Button(
                    action: { onTap(history) },
                    label: { HistoryView(history: history) }
                )
            }
        }
        .onAppear { Task { await presenter.prepare() } }
    }
    
    private struct HistoryView: View {
        let history: DiffusionHistory
        
        var body: some View {
            HStack {
                AsyncImage(
                    url: history.resultImageURL, scale: 1,
                    content: { image in
                        image
                            .resizable()
                            .scaledToFit()
                    },
                    placeholder: { EmptyView() }
                )
                .frame(width: 64, height: 64)
                .background(Color.secondary)
                .cornerRadius(4)
                VStack(alignment: .leading, spacing: 8) {
                    Text(history.modelID)
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundColor(.label)
                    RequestDescriptionView(request: history.request)
                }
            }
        }
    }
    
    private struct RequestDescriptionView: View {
        let request: DiffusionHistory.Request
        
        var body: some View {
            VStack(alignment: .leading) {
                Row(
                    text: request.prompt,
                    image: Image(systemName: "text.bubble")
                )
                Row(
                    text: request.negativePrompt,
                    image: Image(systemName: "xmark.diamond")
                )
                Row(
                    text: String(format: "%u", request.seed),
                    image: Image(systemName: "leaf")
                )
                Row(
                    text: String(
                        format: "Step: %d, Guidance: %g",
                        request.stepCount,
                        request.guidanceScale
                    ),
                    image: Image(systemName: "info.circle")
                )
            }
        }
        
        private struct Row: View {
            let text: String
            let image: Image
            
            var body: some View {
                HStack(spacing: 4) {
                    image
                    Text(text)
                        .lineLimit(1)
                }
                .font(.caption)
                .foregroundColor(.secondaryLabel)
            }
        }
    }
}
