//
//  FearIndexRepository.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

final class FearIndexRepository: FearIndexRepositoryProtocol, @unchecked Sendable {
    private let dataSource: FearIndexDataSourceProtocol

    nonisolated init(dataSource: FearIndexDataSourceProtocol) {
        self.dataSource = dataSource
    }

    nonisolated func fetchCurrent() async throws -> FearIndex {
        let response = try await dataSource.fetch()
        guard let domain = response.fearAndGreed.toDomain() else {
            throw FearIndexError.invalidData
        }
        return domain
    }

    nonisolated func fetchHistory(days: Int) async throws -> [FearIndex] {
        let response = try await dataSource.fetch()
        return response.fearAndGreedHistorical.data.map { $0.toDomain() }
    }
}

enum FearIndexError: Error, Sendable {
    case invalidData
    case networkError
}
