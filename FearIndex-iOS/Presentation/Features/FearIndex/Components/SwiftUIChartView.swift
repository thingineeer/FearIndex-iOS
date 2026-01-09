//
//  SwiftUIChartView.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import SwiftUI
import Charts

struct SwiftUIChartView: View {
    let data: [FearIndex]
    let period: ChartPeriod
    @Binding var selectedValue: FearIndex?

    @Environment(\.colorScheme) private var colorScheme
    @State private var touchLocation: CGPoint = .zero
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                chartContent(geometry: geometry)

                if isDragging, let selected = selectedValue {
                    selectionIndicator(selected, geometry: geometry)
                }
            }
        }
    }

    // MARK: - Chart Content

    @ViewBuilder
    private func chartContent(geometry: GeometryProxy) -> some View {
        Chart(filteredData, id: \.timestamp) { item in
            AreaMark(
                x: .value("Date", item.timestamp),
                y: .value("Score", item.score)
            )
            .foregroundStyle(areaGradient)
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Date", item.timestamp),
                y: .value("Score", item.score)
            )
            .foregroundStyle(lineColor)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.catmullRom)

            if let selected = selectedValue,
               Calendar.current.isDate(selected.timestamp, inSameDayAs: item.timestamp) {
                PointMark(
                    x: .value("Date", item.timestamp),
                    y: .value("Score", item.score)
                )
                .foregroundStyle(accentColor)
                .symbolSize(80)

                RuleMark(x: .value("Date", item.timestamp))
                    .foregroundStyle(accentColor.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 2]))
            }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis { xAxisMarks }
        .chartYAxis { yAxisMarks }
        .chartOverlay { proxy in
            chartOverlayContent(proxy: proxy, geometry: geometry)
        }
    }

    // MARK: - X Axis

    @AxisContentBuilder
    private var xAxisMarks: some AxisContent {
        AxisMarks(values: xAxisValues) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(gridColor)

            AxisValueLabel {
                if let date = value.as(Date.self) {
                    Text(formatXAxisLabel(date))
                        .font(.caption2)
                        .foregroundStyle(labelColor)
                }
            }
        }
    }

    private var xAxisValues: AxisMarkValues {
        switch period {
        case .day:
            return .automatic(desiredCount: 4)
        case .week:
            return .automatic(desiredCount: 7)
        case .month:
            return .automatic(desiredCount: 5)
        case .oneYear:
            return .automatic(desiredCount: 6)
        }
    }

    private func formatXAxisLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")

        switch period {
        case .day:
            formatter.dateFormat = "HH:mm"
        case .week:
            formatter.dateFormat = "E"
        case .month:
            formatter.dateFormat = "M/d"
        case .oneYear:
            formatter.dateFormat = "yy.M"
        }

        return formatter.string(from: date)
    }

    // MARK: - Y Axis

    @AxisContentBuilder
    private var yAxisMarks: some AxisContent {
        AxisMarks(values: [0, 25, 50, 75, 100]) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                .foregroundStyle(gridColor)

            AxisValueLabel {
                if let intValue = value.as(Int.self) {
                    Text("\(intValue)")
                        .font(.caption2)
                        .foregroundStyle(labelColor)
                }
            }
        }
    }

    // MARK: - Chart Overlay

    private func chartOverlayContent(
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) -> some View {
        Rectangle()
            .fill(.clear)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDragChange(value: value, proxy: proxy)
                    }
                    .onEnded { _ in
                        handleDragEnd()
                    }
            )
    }

    private func handleDragChange(value: DragGesture.Value, proxy: ChartProxy) {
        touchLocation = value.location

        guard let date: Date = proxy.value(atX: value.location.x) else { return }

        if let closest = findClosestDataPoint(to: date) {
            let shouldUpdate = selectedValue?.timestamp != closest.timestamp
            if shouldUpdate {
                selectedValue = closest
                triggerHaptic()
            }
        }

        isDragging = true
    }

    private func handleDragEnd() {
        isDragging = false
    }

    // MARK: - Selection Indicator

    private func selectionIndicator(
        _ dataPoint: FearIndex,
        geometry: GeometryProxy
    ) -> some View {
        let xPos = min(
            max(touchLocation.x - 60, 0),
            geometry.size.width - 120
        )

        return VStack(spacing: 2) {
            Text("\(Int(dataPoint.score))")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(colorForScore(dataPoint.score))

            Text(dataPoint.rating.displayText)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(formatTooltipDate(dataPoint.timestamp))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .position(x: xPos + 60, y: 40)
    }

    private func formatTooltipDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")

        switch period {
        case .day:
            formatter.dateFormat = "M월 d일 HH:mm"
        case .week:
            formatter.dateFormat = "M월 d일 (E)"
        case .month:
            formatter.dateFormat = "M월 d일"
        case .oneYear:
            formatter.dateFormat = "yyyy년 M월 d일"
        }

        return formatter.string(from: date)
    }

    // MARK: - Helpers

    private var filteredData: [FearIndex] {
        let calendar = Calendar.current
        let now = Date()

        // 1. 기간 필터링
        let filtered = data.filter { item in
            guard let daysAgo = calendar.dateComponents(
                [.day],
                from: item.timestamp,
                to: now
            ).day else { return false }

            return daysAgo >= 0 && daysAgo <= period.days
        }

        let sorted = filtered.sorted { $0.timestamp < $1.timestamp }

        // 2. 샘플링 (장기 데이터 최적화)
        return sampleData(sorted)
    }

    /// 장기 데이터 샘플링 (성능 최적화)
    private func sampleData(_ data: [FearIndex]) -> [FearIndex] {
        let maxPoints: Int
        switch period {
        case .day, .week, .month:
            return data  // 단기는 샘플링 안함
        case .oneYear:
            maxPoints = 52  // 약 주간 데이터
        }

        guard data.count > maxPoints else { return data }

        // 균등 간격 샘플링
        let step = Double(data.count - 1) / Double(maxPoints - 1)
        var sampled: [FearIndex] = []

        for i in 0..<maxPoints {
            let index = Int(Double(i) * step)
            sampled.append(data[index])
        }

        // 마지막 데이터 포함 보장
        if let last = data.last, sampled.last?.timestamp != last.timestamp {
            sampled[sampled.count - 1] = last
        }

        return sampled
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

    private func colorForScore(_ score: Double) -> Color {
        switch score {
        case 0..<25: return .red
        case 25..<45: return .orange
        case 45..<55: return .yellow
        case 55..<75: return .green
        default: return .mint
        }
    }

    // MARK: - Theme Colors

    private var accentColor: Color {
        .orange
    }

    private var lineColor: Color {
        colorScheme == .dark ? .orange : .orange.opacity(0.9)
    }

    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [
                accentColor.opacity(colorScheme == .dark ? 0.5 : 0.4),
                accentColor.opacity(0.1),
                .clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var gridColor: Color {
        colorScheme == .dark
            ? Color.gray.opacity(0.3)
            : Color.gray.opacity(0.2)
    }

    private var labelColor: Color {
        .secondary
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SwiftUIChartView(
            data: [],
            period: .month,
            selectedValue: .constant(nil)
        )
        .frame(height: 250)
        .padding()
    }
}
