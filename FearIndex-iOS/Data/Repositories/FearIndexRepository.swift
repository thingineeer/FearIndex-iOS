//
//  FearIndexRepository.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

final class FearIndexRepository: FearIndexRepositoryProtocol, @unchecked Sendable {
    private let dataSource: FearIndexDataSourceProtocol

    init(dataSource: FearIndexDataSourceProtocol) {
        self.dataSource = dataSource
    }

    func fetchCurrent(forceRefresh: Bool) async throws -> FearIndex {
        let response = try await dataSource.fetch(forceRefresh: forceRefresh)
        guard let domain = response.fearAndGreed.toDomain() else {
            throw FearIndexError.invalidData
        }
        return domain
    }

    func fetchHistory(days: Int, forceRefresh: Bool) async throws -> [FearIndex] {
        let response = try await dataSource.fetch(forceRefresh: forceRefresh)
        return response.fearAndGreedHistorical.data.map { $0.toDomain() }
    }
}

enum FearIndexError: Error, Sendable {
    case invalidData
    case networkError
}
