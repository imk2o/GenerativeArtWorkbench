//
//  CircularProgressView.swift
//  GenerativeArtWorkbench
//
//  Created by k2o on 2023/04/23.
//

import SwiftUI

struct CircularProgressView: View {
    let progress: Float
    let accentColor: Color
    let trackColor: Color
    let trackWidth: CGFloat
    
    init(
        progress: Float,
        accentColor: Color = .accentColor,
        trackColor: Color = .secondarySystemBackground,
        trackWidth: CGFloat = 2
    ) {
        self.progress = progress
        self.accentColor = accentColor
        self.trackColor = trackColor
        self.trackWidth = trackWidth
    }
    
    var body: some View {
        ZStack {
            // Background Track
            Circle()
                .stroke(lineWidth: trackWidth)
                .foregroundColor(trackColor)
            // Progress Track
            Circle()
                .trim(
                    from: 0,
                    to: CGFloat(min(progress, 1))
                )
                .stroke(style: StrokeStyle(lineWidth: trackWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(accentColor)
                .rotationEffect(Angle(degrees: 270))
                .animation(.linear, value: progress)
        }
    }
}

struct IndeterminateCircularProgressView: View {
    let accentColor: Color
    let trackColor: Color
    let trackWidth: CGFloat
    
    init(
        accentColor: Color = .accentColor,
        trackColor: Color = .secondarySystemBackground,
        trackWidth: CGFloat = 2
    ) {
        self.accentColor = accentColor
        self.trackColor = trackColor
        self.trackWidth = trackWidth
    }
    
    @State private var angle: Angle = .init(degrees: 0)
    
    var body: some View {
        ZStack {
            // Background Track
            Circle()
                .stroke(lineWidth: trackWidth)
                .foregroundColor(trackColor)
            // Progress Track
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(style: StrokeStyle(lineWidth: trackWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(accentColor)
                .rotationEffect(angle)
        }
        .onAppear {
            // レイアウト変更がアニメーションに混入しないよう、1サイクル置いて回転を開始
            Task {
                withAnimation(
                    .linear(duration: 1)
                    .repeatForever(autoreverses: false)
                ) {
                    angle = Angle(degrees: 360)
                }
            }
        }
    }
}

struct CircularProgressView_Previews: PreviewProvider {
    static var previews: some View {
        Preview()
    }
    
    private struct Preview: View {
        @State private var progress: Float? = 0.0

        var body: some View {
            VStack {
                if let progress {
                    CircularProgressView(progress: progress)
                        .frame(width: 40, height: 40)
                } else {
                    IndeterminateCircularProgressView()
                        .frame(width: 40, height: 40)
                }
                HStack {
                    Button("Increment") {
                        if progress == nil {
                            progress = 0
                        }
                        progress? += 0.1
                    }
                    Button("Indeterminate") {
                        progress = nil
                    }
                }
            }
        }
    }
}
