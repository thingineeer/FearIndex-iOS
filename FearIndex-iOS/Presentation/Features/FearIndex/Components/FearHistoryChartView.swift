//
//  FearHistoryChartView.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import SwiftUI
import Charts

struct FearHistoryChartView: View {
    let data: [FearIndex]
    let cryptoData: [FearIndex]

    @State private var selectedPeriod: ChartPeriod = .month
    @State private var selectedValue: FearIndex?

    init(data: [FearIndex], cryptoData: [FearIndex] = []) {
        self.data = data
        self.cryptoData = cryptoData
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            controlsRow
            selectedValueHeader
            chartView
            periodSelector
            attributionView
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    @ViewBuilder
    private var selectedValueHeader: some View {
        if let selected = selectedValue {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(selected.score))")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(colorForScore(selected.score))

                    Text(selected.rating.displayText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(formattedDate(selected.timestamp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var chartView: some View {
        SwiftUIChartView(
            data: currentData,
            period: selectedPeriod,
            selectedValue: $selectedValue
        )
        .frame(height: 250)
    }

    /// 현재 기간에 맞는 데이터 선택
    private var currentData: [FearIndex] {
        if selectedPeriod.needsLongTermData && !cryptoData.isEmpty {
            return cryptoData
        }
        return data
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

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }

    private var attributionView: some View {
        HStack(spacing: 4) {
            Image(systemName: "chart.xyaxis.line")
                .font(.caption2)
            Text("Powered by SwiftUI Charts")
                .font(.caption2)
        }
        .foregroundStyle(.secondary)
    }

    private var controlsRow: some View {
        HStack {
            Text("히스토리")
                .font(.headline)
            Spacer()
            dataCountLabel
        }
    }

    private var dataCountLabel: some View {
        Text("\(filteredDataCount)개")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(ChartPeriod.allCases, id: \.self) { period in
                periodButton(period)
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func periodButton(_ period: ChartPeriod) -> some View {
        Button {
            selectedPeriod = period
        } label: {
            Text(period.title)
                .font(.subheadline)
                .fontWeight(selectedPeriod == period ? .semibold : .regular)
                .foregroundStyle(selectedPeriod == period ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedPeriod == period ? Color.blue : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var filteredDataCount: Int {
        let calendar = Calendar.current
        let now = Date()

        return currentData.filter { item in
            guard let daysAgo = calendar.dateComponents(
                [.day],
                from: item.timestamp,
                to: now
            ).day else { return false }

            return daysAgo >= 0 && daysAgo <= selectedPeriod.days
        }.count
    }
}

// MARK: - Chart Period

enum ChartPeriod: CaseIterable {
    case week       // 1주
    case month      // 1개월
    case oneYear    // 1년
    case fiveYear   // 5년
    case max        // 전체 (2018년부터)

    var title: String {
        switch self {
        case .week: return "1주"
        case .month: return "1월"
        case .oneYear: return "1년"
        case .fiveYear: return "5년"
        case .max: return "MAX"
        }
    }

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .oneYear: return 365
        case .fiveYear: return 365 * 5
        case .max: return 365 * 10  // 2018년부터 약 7년, 넉넉히 10년
        }
    }

    /// 차트에 보이는 화면당 일수 (스크롤용)
    var visibleDays: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .oneYear: return 90       // 1년치 중 3개월씩 보여줌
        case .fiveYear: return 365     // 5년치 중 1년씩 보여줌
        case .max: return 365 * 2      // 전체 중 2년씩 보여줌
        }
    }

    /// 장기 데이터 필요 여부
    var needsLongTermData: Bool {
        switch self {
        case .week, .month, .oneYear:
            return false
        case .fiveYear, .max:
            return true
        }
    }
}

#Preview {
    FearHistoryChartView(data: [])
        .padding()
}
