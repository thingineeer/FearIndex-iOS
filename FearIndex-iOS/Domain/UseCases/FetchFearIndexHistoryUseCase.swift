//
//  FetchFearIndexHistoryUseCase.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

protocol FetchFearIndexHistoryUseCaseProtocol: Sendable {
    func execute(days: Int, forceRefresh: Bool) async throws -> [FearIndex]
}

extension FetchFearIndexHistoryUseCaseProtocol {
    func execute(days: Int) async throws -> [FearIndex] {
        try await execute(days: days, forceRefresh: false)
    }
}

struct FetchFearIndexHistoryUseCase: FetchFearIndexHistoryUseCaseProtocol {
    private let repository: FearIndexRepositoryProtocol

    init(repository: FearIndexRepositoryProtocol) {
        self.repository = repository
    }

    func execute(days: Int, forceRefresh: Bool) async throws -> [FearIndex] {
        try await repository.fetchHistory(days: days, forceRefresh: forceRefresh)
    }
}
