//
//  TradingViewChartView.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import SwiftUI
import LightweightCharts

// MARK: - SwiftUI Wrapper

struct TradingViewChartView: UIViewRepresentable {
    let data: [FearIndex]
    let period: ChartPeriod
    @Binding var selectedValue: FearIndex?

    func makeUIView(context: Context) -> LightweightCharts {
        let chartOptions = ChartOptions(
            timeScale: TimeScaleOptions(
                borderVisible: false,
                timeVisible: false,
                secondsVisible: false
            ),
            crosshair: CrosshairOptions(
                mode: .magnet,
                vertLine: CrosshairLineOptions(
                    color: "rgba(255, 152, 0, 0.8)",
                    width: .one,
                    visible: true,
                    labelVisible: true
                ),
                horzLine: CrosshairLineOptions(
                    color: "rgba(255, 152, 0, 0.8)",
                    width: .one,
                    visible: true,
                    labelVisible: true
                )
            )
        )

        let chart = LightweightCharts(options: chartOptions)
        chart.delegate = context.coordinator

        // 이벤트 구독 - 클릭 및 크로스헤어 이동 감지
        chart.subscribeClick()
        chart.subscribeCrosshairMove()

        context.coordinator.chart = chart
        context.coordinator.setupSeries(chart: chart)
        context.coordinator.updateData(filteredData)

        return chart
    }

    func updateUIView(_ chart: LightweightCharts, context: Context) {
        // 부모 참조 업데이트
        context.coordinator.parent = self
        context.coordinator.currentData = filteredData
        context.coordinator.updateData(filteredData)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    var filteredData: [FearIndex] {
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
}

// MARK: - Coordinator

extension TradingViewChartView {
    final class Coordinator: NSObject, ChartDelegate {
        var parent: TradingViewChartView
        var chart: LightweightCharts?
        var areaSeries: AreaSeries?
        var currentData: [FearIndex] = []
        private var lastSelectedTimestamp: Date?

        init(parent: TradingViewChartView) {
            self.parent = parent
            self.currentData = parent.filteredData
        }

        func setupSeries(chart: LightweightCharts) {
            let options = AreaSeriesOptions(
                topColor: "rgba(255, 152, 0, 0.4)",
                bottomColor: "rgba(255, 152, 0, 0.0)",
                lineColor: "rgba(255, 152, 0, 1)",
                lineWidth: .two,
                crosshairMarkerVisible: true,
                crosshairMarkerRadius: 6
            )

            areaSeries = chart.addAreaSeries(options: options)
        }

        func updateData(_ data: [FearIndex]) {
            currentData = data

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            let chartData: [AreaData] = data.map { item in
                AreaData(
                    time: .string(dateFormatter.string(from: item.timestamp)),
                    value: item.score
                )
            }

            areaSeries?.setData(data: chartData)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.chart?.timeScale().fitContent()
            }
        }

        // MARK: - ChartDelegate

        func didClick(onChart chart: ChartApi, parameters: MouseEventParams) {
            handleCrosshair(parameters)
        }

        func didCrosshairMove(onChart chart: ChartApi, parameters: MouseEventParams) {
            handleCrosshair(parameters)
        }

        func didVisibleTimeRangeChange(
            onChart chart: ChartApi,
            parameters: TimeRange?
        ) {}

        private func handleCrosshair(_ parameters: MouseEventParams) {
            guard let time = parameters.time else {
                DispatchQueue.main.async { [weak self] in
                    self?.parent.selectedValue = nil
                }
                return
            }

            // 시간 문자열에서 날짜 추출
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            var targetDate: Date?

            switch time {
            case .businessDayString(let dateString):
                targetDate = dateFormatter.date(from: dateString)
            case .utc(let timestamp):
                targetDate = Date(timeIntervalSince1970: timestamp)
            case .businessDay(let businessDay):
                let components = DateComponents(
                    year: businessDay.year,
                    month: businessDay.month,
                    day: businessDay.day
                )
                targetDate = Calendar.current.date(from: components)
            }

            guard let date = targetDate else {
                DispatchQueue.main.async { [weak self] in
                    self?.parent.selectedValue = nil
                }
                return
            }

            // 현재 데이터에서 가장 가까운 포인트 찾기
            let closest = currentData.min { a, b in
                abs(a.timestamp.timeIntervalSince(date)) <
                abs(b.timestamp.timeIntervalSince(date))
            }

            // 이전 선택과 다를 때만 업데이트 + 햅틱
            if lastSelectedTimestamp != closest?.timestamp {
                lastSelectedTimestamp = closest?.timestamp
                triggerHaptic()

                DispatchQueue.main.async { [weak self] in
                    self?.parent.selectedValue = closest
                }
            }
        }

        private func triggerHaptic() {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

// MARK: - Preview

#Preview {
    TradingViewChartView(
        data: [],
        period: .month,
        selectedValue: .constant(nil)
    )
    .frame(height: 300)
    .padding()
}
