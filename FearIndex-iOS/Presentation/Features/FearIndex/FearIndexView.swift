//
//  FearIndexView.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import SwiftUI

struct FearIndexView: View {
    @State var interactor: FearIndexInteractor
    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            homeTab
                .tabItem {
                    Label("홈", systemImage: "gauge.with.needle")
                }
                .tag(Tab.home)

            chartTab
                .tabItem {
                    Label("차트", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.chart)
        }
        .task { await interactor.loadFearIndex() }
        .onAppear { interactor.startAutoRefresh() }
        .onDisappear { interactor.stopAutoRefresh() }
    }

    private var homeTab: some View {
        NavigationStack {
            homeContent
                .navigationTitle("Fear & Greed")
                .background(Color(.systemGroupedBackground))
                .refreshable { await interactor.refresh() }
        }
    }

    private var chartTab: some View {
        NavigationStack {
            chartContent
                .navigationTitle("차트")
                .background(Color(.systemGroupedBackground))
                .refreshable { await interactor.refresh() }
        }
    }

    @ViewBuilder
    private var homeContent: some View {
        switch interactor.state {
        case .idle, .loading:
            loadingView
        case .loaded(let fearIndex):
            homeLoadedView(fearIndex)
        case .error(let message):
            errorView(message)
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        switch interactor.state {
        case .idle, .loading:
            loadingView
        case .loaded(let fearIndex):
            chartLoadedView(fearIndex)
        case .error(let message):
            errorView(message)
        }
    }

    private func homeLoadedView(_ fearIndex: FearIndex) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                gaugeSection(fearIndex)
                comparisonSection(fearIndex)
                miniChartSection
                timestampView(fearIndex.timestamp)
            }
            .padding()
        }
    }

    private func chartLoadedView(_ fearIndex: FearIndex) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                currentScoreHeader(fearIndex)
                FearHistoryChartView(
                    data: interactor.historyData,
                    cryptoData: interactor.cryptoHistoryData
                )
                timestampView(fearIndex.timestamp)
            }
            .padding()
        }
    }

    private func currentScoreHeader(_ fearIndex: FearIndex) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("현재 지수")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(Int(fearIndex.score))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))

                    Text(fearIndex.rating.displayText)
                        .font(.headline)
                        .foregroundStyle(colorForRating(fearIndex.rating))
                }
            }
            Spacer()

            changeIndicator(fearIndex)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func changeIndicator(_ fearIndex: FearIndex) -> some View {
        let change = fearIndex.score - fearIndex.previousClose
        let color = change > 0 ? Color.green : (change < 0 ? .red : .secondary)
        let symbol = change > 0 ? "arrow.up" : (change < 0 ? "arrow.down" : "minus")

        return VStack(alignment: .trailing, spacing: 2) {
            Text("전일 대비")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 2) {
                Image(systemName: symbol)
                    .font(.caption)
                Text(String(format: "%.1f", abs(change)))
                    .font(.headline)
            }
            .foregroundStyle(color)
        }
    }

    private var miniChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("최근 추이")
                    .font(.headline)
                Spacer()
                Button("더보기") {
                    selectedTab = .chart
                }
                .font(.subheadline)
            }

            MiniChartView(data: interactor.historyData)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("데이터 로딩 중...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func gaugeSection(_ fearIndex: FearIndex) -> some View {
        VStack {
            FearGaugeView(score: fearIndex.score, rating: fearIndex.rating)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func comparisonSection(_ fearIndex: FearIndex) -> some View {
        FearComparisonCard(
            currentScore: fearIndex.score,
            previousClose: fearIndex.previousClose,
            previous1Week: fearIndex.previous1Week,
            previous1Month: fearIndex.previous1Month,
            previous1Year: fearIndex.previous1Year
        )
    }

    private func timestampView(_ date: Date) -> some View {
        HStack {
            Spacer()
            Text("업데이트: \(formattedDate(date))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: date)
    }

    private func colorForRating(_ rating: FearIndex.Rating) -> Color {
        switch rating {
        case .extremeFear: return .red
        case .fear: return .orange
        case .neutral: return .yellow
        case .greed: return .green
        case .extremeGreed: return .mint
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text(message)
                .foregroundStyle(.secondary)

            Button("다시 시도") {
                Task { await interactor.refresh() }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Tab

extension FearIndexView {
    enum Tab {
        case home
        case chart
    }
}

// MARK: - Mini Chart

private struct MiniChartView: View {
    let data: [FearIndex]

    var body: some View {
        if recentData.isEmpty {
            Text("데이터 없음")
                .foregroundStyle(.secondary)
                .frame(height: 100)
        } else {
            GeometryReader { geometry in
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(max(recentData.count - 1, 1))

                    for (index, item) in recentData.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = height - (CGFloat(item.score) / 100.0 * height)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
            }
            .frame(height: 100)
        }
    }

    private var recentData: [FearIndex] {
        let calendar = Calendar.current
        let now = Date()

        return data.filter { item in
            guard let daysAgo = calendar.dateComponents(
                [.day],
                from: item.timestamp,
                to: now
            ).day else { return false }

            return daysAgo >= 0 && daysAgo <= 7
        }
        .sorted { $0.timestamp < $1.timestamp }
    }
}

#Preview {
    let interactor = FearIndexInteractor(
        fetchUseCase: PreviewFetchFearIndexUseCase(),
        fetchHistoryUseCase: PreviewFetchHistoryUseCase(),
        fetchCryptoUseCase: PreviewFetchCryptoUseCase()
    )
    return FearIndexView(interactor: interactor)
}

// MARK: - Preview Helpers

private struct PreviewFetchFearIndexUseCase: FetchFearIndexUseCaseProtocol {
    func execute(forceRefresh: Bool) async throws -> FearIndex {
        FearIndex(
            score: 46,
            rating: .neutral,
            timestamp: Date(),
            previousClose: 52,
            previous1Week: 44,
            previous1Month: 38,
            previous1Year: 34
        )
    }
}

private struct PreviewFetchHistoryUseCase: FetchFearIndexHistoryUseCaseProtocol {
    func execute(days: Int, forceRefresh: Bool) async throws -> [FearIndex] { [] }
}

private struct PreviewFetchCryptoUseCase: FetchCryptoFearIndexUseCaseProtocol {
    func execute(forceRefresh: Bool) async throws -> [FearIndex] { [] }
}
