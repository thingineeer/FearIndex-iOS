//
//  FetchFearIndexHistoryUseCase.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

protocol FetchFearIndexHistoryUseCaseProtocol: Sendable {
    func execute(days: Int) async throws -> [FearIndex]
}

struct FetchFearIndexHistoryUseCase: FetchFearIndexHistoryUseCaseProtocol {
    private let repository: FearIndexRepositoryProtocol

    init(repository: FearIndexRepositoryProtocol) {
        self.repository = repository
    }

    func execute(days: Int) async throws -> [FearIndex] {
        try await repository.fetchHistory(days: days)
    }
}
