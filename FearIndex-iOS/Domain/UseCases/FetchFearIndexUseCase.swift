//
//  FetchFearIndexUseCase.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

protocol FetchFearIndexUseCaseProtocol: Sendable {
    func execute() async throws -> FearIndex
}

struct FetchFearIndexUseCase: FetchFearIndexUseCaseProtocol {
    private let repository: FearIndexRepositoryProtocol

    init(repository: FearIndexRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> FearIndex {
        try await repository.fetchCurrent()
    }
}
