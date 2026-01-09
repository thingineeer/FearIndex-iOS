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
    @State private var scrollPosition: Date = Date()

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                scrollableChart(geometry: geometry)

                if isDragging, let selected = selectedValue {
                    selectionIndicator(selected, geometry: geometry)
                }
            }
        }
        .onAppear {
            // 스크롤 초기 위치를 가장 최근 데이터로 설정
            if let lastDate = filteredData.last?.timestamp {
                scrollPosition = lastDate
            }
        }
    }

    // MARK: - Scrollable Chart

    @ViewBuilder
    private func scrollableChart(geometry: GeometryProxy) -> some View {
        let chartWidth = calculateChartWidth(geometry: geometry)

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
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: visibleDomainLength)
        .chartScrollPosition(x: $scrollPosition)
        .chartOverlay { proxy in
            chartOverlayContent(proxy: proxy, geometry: geometry)
        }
        .frame(minWidth: chartWidth)
    }

    /// 차트 너비 계산 (스크롤을 위해)
    private func calculateChartWidth(geometry: GeometryProxy) -> CGFloat {
        let dataCount = filteredData.count
        let visibleCount = period.visibleDays

        if dataCount <= visibleCount {
            return geometry.size.width
        }

        let ratio = CGFloat(dataCount) / CGFloat(visibleCount)
        return geometry.size.width * ratio
    }

    /// X축에 보이는 시간 범위 (초 단위)
    private var visibleDomainLength: Int {
        period.visibleDays * 24 * 60 * 60
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
        case .week:
            // 7일 → 7개 라벨 (매일)
            return .automatic(desiredCount: 7)
        case .month:
            // 30일 → 5개 라벨 (약 6일마다)
            return .automatic(desiredCount: 5)
        case .oneYear:
            // 90일 visible → 3개 라벨 (월별)
            return .automatic(desiredCount: 3)
        case .fiveYear:
            // 365일 visible → 4개 라벨 (분기별)
            return .automatic(desiredCount: 4)
        case .max:
            // 730일 visible → 4개 라벨 (6개월마다)
            return .automatic(desiredCount: 4)
        }
    }

    private func formatXAxisLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")

        switch period {
        case .week:
            // 요일 표시: 월, 화, 수...
            formatter.dateFormat = "E"
        case .month:
            // 날짜 표시: 1/5, 1/12...
            formatter.dateFormat = "M/d"
        case .oneYear:
            // 년월 표시: 24.1, 24.2... (년도 포함으로 중복 방지)
            formatter.dateFormat = "yy.M"
        case .fiveYear:
            // 년도 + 분기: 24.1, 24.7...
            formatter.dateFormat = "yy.M"
        case .max:
            // 년도만: 2020, 2022...
            formatter.dateFormat = "yyyy"
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
        case .week:
            formatter.dateFormat = "M월 d일 (E)"
        case .month:
            formatter.dateFormat = "M월 d일"
        case .oneYear, .fiveYear, .max:
            formatter.dateFormat = "yyyy년 M월 d일"
        }

        return formatter.string(from: date)
    }

    // MARK: - Helpers

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
