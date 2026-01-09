//
//  FearIndexInteractor.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation
import Observation

protocol FearIndexInteractable: AnyObject {
    func loadFearIndex() async
    func refresh() async
    func startAutoRefresh()
    func stopAutoRefresh()
}

protocol FearIndexListener: AnyObject {
    func fearIndexDidUpdate(_ index: FearIndex)
}

@Observable
@MainActor
final class FearIndexInteractor: FearIndexInteractable {
    enum ViewState: Sendable {
        case idle
        case loading
        case loaded(FearIndex)
        case error(String)
    }

    private(set) var state: ViewState = .idle
    private(set) var historyData: [FearIndex] = []
    private(set) var cryptoHistoryData: [FearIndex] = []  // 2018년부터의 장기 데이터
    private(set) var lastUpdated: Date?
    private(set) var isAutoRefreshEnabled = false
    private(set) var isCryptoLoading = false

    private let fetchUseCase: FetchFearIndexUseCaseProtocol
    private let fetchHistoryUseCase: FetchFearIndexHistoryUseCaseProtocol
    private let fetchCryptoUseCase: FetchCryptoFearIndexUseCaseProtocol?
    weak var listener: FearIndexListener?

    private var autoRefreshTask: Task<Void, Never>?
    private let autoRefreshInterval: TimeInterval = 5 * 60  // 5분
    private var cryptoDataLoaded = false

    init(
        fetchUseCase: FetchFearIndexUseCaseProtocol,
        fetchHistoryUseCase: FetchFearIndexHistoryUseCaseProtocol,
        fetchCryptoUseCase: FetchCryptoFearIndexUseCaseProtocol? = nil
    ) {
        self.fetchUseCase = fetchUseCase
        self.fetchHistoryUseCase = fetchHistoryUseCase
        self.fetchCryptoUseCase = fetchCryptoUseCase
    }

    func loadFearIndex() async {
        await fetchData(forceRefresh: false)
    }

    func refresh() async {
        await fetchData(forceRefresh: true)
    }

    /// Crypto 장기 데이터 로드 (차트 탭에서 호출)
    func loadCryptoDataIfNeeded() async {
        guard !cryptoDataLoaded, !isCryptoLoading else { return }
        guard let cryptoUseCase = fetchCryptoUseCase else { return }

        isCryptoLoading = true

        do {
            let cryptoData = try await cryptoUseCase.execute(forceRefresh: false)
            self.cryptoHistoryData = cryptoData
            self.cryptoDataLoaded = true
            Logger.info("Crypto history loaded: \(cryptoData.count) data points")
        } catch {
            Logger.error("Crypto history fetch failed: \(error.localizedDescription)")
        }

        isCryptoLoading = false
    }

    private func fetchData(forceRefresh: Bool) async {
        // 로딩 중이 아닐 때만 상태 변경
        if case .loading = state { return }

        state = .loading

        do {
            async let current = fetchUseCase.execute(forceRefresh: forceRefresh)
            async let history = fetchHistoryUseCase.execute(days: 365, forceRefresh: forceRefresh)

            let (currentIndex, historyIndices) = try await (current, history)

            state = .loaded(currentIndex)
            historyData = historyIndices
            lastUpdated = Date()
            listener?.fearIndexDidUpdate(currentIndex)

            Logger.info("Fear Index updated: \(Int(currentIndex.score)) (\(forceRefresh ? "forced" : "cached"))")
        } catch {
            state = .error(mapError(error))
            Logger.error("Fear Index fetch failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Auto Refresh

    func startAutoRefresh() {
        guard !isAutoRefreshEnabled else { return }

        isAutoRefreshEnabled = true
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.autoRefreshInterval ?? 300))

                guard !Task.isCancelled else { break }

                await self?.fetchData(forceRefresh: true)
            }
        }

        Logger.info("Auto refresh started (interval: \(Int(autoRefreshInterval))s)")
    }

    func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
        isAutoRefreshEnabled = false

        Logger.info("Auto refresh stopped")
    }

    private func mapError(_ error: Error) -> String {
        switch error {
        case NetworkError.httpError(let code):
            return "서버 오류 (\(code))"
        case NetworkError.invalidResponse:
            return "잘못된 응답"
        case FearIndexError.invalidData:
            return "데이터 파싱 실패"
        default:
            return "네트워크 오류"
        }
    }
}
