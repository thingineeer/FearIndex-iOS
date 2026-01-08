//
//  FearComparisonCard.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import SwiftUI

struct FearComparisonCard: View {
    let currentScore: Double
    let previousClose: Double
    let previous1Week: Double
    let previous1Month: Double
    let previous1Year: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("비교")
                .font(.headline)

            HStack(spacing: 16) {
                comparisonItem("전일", previousClose)
                comparisonItem("1주전", previous1Week)
                comparisonItem("1개월전", previous1Month)
                comparisonItem("1년전", previous1Year)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func comparisonItem(_ label: String, _ value: Double) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(Int(value))")
                .font(.title3)
                .fontWeight(.semibold)

            changeIndicator(from: value)
        }
        .frame(maxWidth: .infinity)
    }

    private func changeIndicator(from previousValue: Double) -> some View {
        let change = currentScore - previousValue
        let color = changeColor(change)
        let symbol = changeSymbol(change)

        return HStack(spacing: 2) {
            Image(systemName: symbol)
                .font(.caption2)
            Text("\(abs(Int(change)))")
                .font(.caption)
        }
        .foregroundStyle(color)
    }

    private func changeColor(_ change: Double) -> Color {
        if change > 0 { return .green }
        if change < 0 { return .red }
        return .secondary
    }

    private func changeSymbol(_ change: Double) -> String {
        if change > 0 { return "arrow.up" }
        if change < 0 { return "arrow.down" }
        return "minus"
    }
}

#Preview {
    FearComparisonCard(
        currentScore: 46,
        previousClose: 52,
        previous1Week: 44,
        previous1Month: 38,
        previous1Year: 34
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
