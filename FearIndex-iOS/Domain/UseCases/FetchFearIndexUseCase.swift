//
//  FetchFearIndexUseCase.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

protocol FetchFearIndexUseCaseProtocol: Sendable {
    func execute(forceRefresh: Bool) async throws -> FearIndex
}

extension FetchFearIndexUseCaseProtocol {
    func execute() async throws -> FearIndex {
        try await execute(forceRefresh: false)
    }
}

struct FetchFearIndexUseCase: FetchFearIndexUseCaseProtocol {
    private let repository: FearIndexRepositoryProtocol

    init(repository: FearIndexRepositoryProtocol) {
        self.repository = repository
    }

    func execute(forceRefresh: Bool) async throws -> FearIndex {
        try await repository.fetchCurrent(forceRefresh: forceRefresh)
    }
}
