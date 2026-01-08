//
//  FearGaugeView.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import SwiftUI

struct FearGaugeView: View {
    let score: Double
    let rating: FearIndex.Rating

    private let minAngle: Double = -135
    private let maxAngle: Double = 135

    var body: some View {
        ZStack {
            gaugeBackground
            needleView
            centerCircle
            scoreLabel
        }
        .frame(width: 280, height: 200)
    }

    private var gaugeBackground: some View {
        GaugeArcView()
            .frame(width: 260, height: 260)
            .offset(y: 30)
    }

    private var needleView: some View {
        NeedleShape()
            .fill(Color.primary)
            .frame(width: 8, height: 100)
            .offset(y: -20)
            .rotationEffect(.degrees(needleAngle))
            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: score)
    }

    private var centerCircle: some View {
        Circle()
            .fill(Color.primary)
            .frame(width: 20, height: 20)
            .offset(y: 30)
    }

    private var scoreLabel: some View {
        VStack(spacing: 4) {
            Text("\(Int(score))")
                .font(.system(size: 48, weight: .bold, design: .rounded))
            Text(rating.displayText)
                .font(.headline)
                .foregroundStyle(colorForRating)
        }
        .offset(y: 90)
    }

    private var needleAngle: Double {
        let normalized = score / 100.0
        return minAngle + (normalized * (maxAngle - minAngle))
    }

    private var colorForRating: Color {
        switch rating {
        case .extremeFear: return .red
        case .fear: return .orange
        case .neutral: return .yellow
        case .greed: return .green
        case .extremeGreed: return .mint
        }
    }
}

private struct GaugeArcView: View {
    var body: some View {
        ZStack {
            arcSegment(start: 0.0, end: 0.2, color: .red)
            arcSegment(start: 0.2, end: 0.4, color: .orange)
            arcSegment(start: 0.4, end: 0.6, color: .yellow)
            arcSegment(start: 0.6, end: 0.8, color: .green)
            arcSegment(start: 0.8, end: 1.0, color: .mint)
            tickMarks
        }
    }

    private func arcSegment(
        start: Double,
        end: Double,
        color: Color
    ) -> some View {
        ArcShape(startPercent: start, endPercent: end)
            .stroke(color, lineWidth: 24)
    }

    private var tickMarks: some View {
        ForEach(0..<11) { index in
            TickMark(index: index)
        }
    }
}

private struct ArcShape: Shape {
    let startPercent: Double
    let endPercent: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 12

        let startAngle = Angle(degrees: -225 + (startPercent * 270))
        let endAngle = Angle(degrees: -225 + (endPercent * 270))

        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

private struct NeedleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width / 2, y: 0))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()

        return path
    }
}

private struct TickMark: View {
    let index: Int

    var body: some View {
        Rectangle()
            .fill(Color.secondary)
            .frame(width: 2, height: index % 5 == 0 ? 12 : 6)
            .offset(y: -105)
            .rotationEffect(.degrees(tickAngle))
    }

    private var tickAngle: Double {
        -135 + (Double(index) * 27)
    }
}

#Preview {
    FearGaugeView(score: 46, rating: .neutral)
}
