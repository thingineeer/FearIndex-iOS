//
//  FetchCryptoFearIndexUseCase.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

protocol FetchCryptoFearIndexUseCaseProtocol: Sendable {
    func execute(forceRefresh: Bool) async throws -> [FearIndex]
}

extension FetchCryptoFearIndexUseCaseProtocol {
    func execute() async throws -> [FearIndex] {
        try await execute(forceRefresh: false)
    }
}

struct FetchCryptoFearIndexUseCase: FetchCryptoFearIndexUseCaseProtocol {
    private let dataSource: CryptoFearIndexDataSourceProtocol

    init(dataSource: CryptoFearIndexDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func execute(forceRefresh: Bool) async throws -> [FearIndex] {
        let response = try await dataSource.fetchAll(forceRefresh: forceRefresh)
        return response.data.map { $0.toDomain() }
    }
}
