//
//  InteractiveChartView.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import SwiftUI
import Charts

struct InteractiveChartView: View {
    let data: [FearIndex]
    let period: ChartPeriod

    @State private var selectedDataPoint: FearIndex?
    @State private var touchLocation: CGPoint = .zero
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                chartContent(geometry: geometry)
                if isDragging, let selected = selectedDataPoint {
                    tooltipView(selected, geometry: geometry)
                }
            }
        }
        .frame(height: 200)
    }

    private func chartContent(geometry: GeometryProxy) -> some View {
        Chart(filteredData, id: \.timestamp) { item in
            LineMark(
                x: .value("날짜", item.timestamp),
                y: .value("지수", item.score)
            )
            .foregroundStyle(lineGradient)
            .lineStyle(StrokeStyle(lineWidth: 2))

            AreaMark(
                x: .value("날짜", item.timestamp),
                y: .value("지수", item.score)
            )
            .foregroundStyle(areaGradient)

            if let selected = selectedDataPoint,
               selected.timestamp == item.timestamp {
                PointMark(
                    x: .value("날짜", item.timestamp),
                    y: .value("지수", item.score)
                )
                .foregroundStyle(.orange)
                .symbolSize(100)
            }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: xAxisCount)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel(format: xAxisFormat)
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.gray.opacity(0.3))
                AxisValueLabel {
                    if let intValue = value.as(Int.self) {
                        Text("\(intValue)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(dragGesture(proxy: proxy, geometry: geo))
            }
        }
    }

    private func tooltipView(
        _ dataPoint: FearIndex,
        geometry: GeometryProxy
    ) -> some View {
        let xPos = min(
            max(touchLocation.x - 50, 0),
            geometry.size.width - 100
        )

        return VStack(spacing: 4) {
            Text("\(Int(dataPoint.score))")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(colorForScore(dataPoint.score))

            Text(dataPoint.rating.displayText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(formattedDate(dataPoint.timestamp))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .position(x: xPos + 50, y: 50)
    }

    private func dragGesture(
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let location = value.location
                touchLocation = location

                if let date: Date = proxy.value(atX: location.x) {
                    if let closest = findClosestDataPoint(to: date) {
                        if selectedDataPoint?.timestamp != closest.timestamp {
                            selectedDataPoint = closest
                            triggerHaptic()
                        }
                    }
                }
                isDragging = true
            }
            .onEnded { _ in
                isDragging = false
                selectedDataPoint = nil
            }
    }

    private func findClosestDataPoint(to date: Date) -> FearIndex? {
        filteredData.min { a, b in
            abs(a.timestamp.timeIntervalSince(date)) <
            abs(b.timestamp.timeIntervalSince(date))
        }
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private var filteredData: [FearIndex] {
        let calendar = Calendar.current
        let now = Date()

        let filtered = data.filter { item in
            guard let daysAgo = calendar.dateComponents(
                [.day],
                from: item.timestamp,
                to: now
            ).day else { return false }

            return daysAgo >= 0 && daysAgo <= period.days
        }

        return filtered.sorted { $0.timestamp < $1.timestamp }
    }

    private var xAxisCount: Int {
        switch period {
        case .day: return 4
        case .week: return 7
        case .month: return 5
        case .oneYear: return 6
        }
    }

    private var xAxisFormat: Date.FormatStyle {
        switch period {
        case .day:
            return .dateTime.hour().minute()
        case .week:
            return .dateTime.weekday(.abbreviated)
        case .month:
            return .dateTime.month(.abbreviated).day()
        case .oneYear:
            return .dateTime.month(.abbreviated)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }

    private func colorForScore(_ score: Double) -> Color {
        switch score {
        case 0..<25: return .red
        case 25..<45: return .orange
        case 45..<55: return .yellow
        case 55..<75: return .green
        default: return .mint
        }
    }

    private var lineGradient: LinearGradient {
        LinearGradient(
            colors: [.orange, .red],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [.orange.opacity(0.4), .orange.opacity(0.1), .clear],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    InteractiveChartView(data: [], period: .month)
        .padding()
}
