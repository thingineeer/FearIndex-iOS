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

    private let fetchUseCase: FetchFearIndexUseCaseProtocol
    private let fetchHistoryUseCase: FetchFearIndexHistoryUseCaseProtocol
    weak var listener: FearIndexListener?

    init(
        fetchUseCase: FetchFearIndexUseCaseProtocol,
        fetchHistoryUseCase: FetchFearIndexHistoryUseCaseProtocol
    ) {
        self.fetchUseCase = fetchUseCase
        self.fetchHistoryUseCase = fetchHistoryUseCase
    }

    func loadFearIndex() async {
        state = .loading

        do {
            async let current = fetchUseCase.execute()
            async let history = fetchHistoryUseCase.execute(days: 365)

            let (currentIndex, historyIndices) = try await (current, history)

            state = .loaded(currentIndex)
            historyData = historyIndices
            listener?.fearIndexDidUpdate(currentIndex)
        } catch {
            state = .error(mapError(error))
        }
    }

    func refresh() async {
        await loadFearIndex()
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
