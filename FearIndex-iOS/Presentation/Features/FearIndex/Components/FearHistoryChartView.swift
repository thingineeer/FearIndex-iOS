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

    @State private var selectedPeriod: ChartPeriod = .week
    @State private var selectedValue: FearIndex?

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
    case day        // 1일
    case week       // 7일
    case month      // 30일
    case oneYear    // 1년

    var title: String {
        switch self {
        case .day: return "1일"
        case .week: return "7일"
        case .month: return "30일"
        case .oneYear: return "1년"
        }
    }

    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .oneYear: return 365
        }
    }
}

#Preview {
    FearHistoryChartView(data: [])
        .padding()
}
