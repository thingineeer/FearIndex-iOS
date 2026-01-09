//
//  FearIndexRepositoryProtocol.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

protocol FearIndexRepositoryProtocol: Sendable {
    func fetchCurrent(forceRefresh: Bool) async throws -> FearIndex
    func fetchHistory(days: Int, forceRefresh: Bool) async throws -> [FearIndex]
}

extension FearIndexRepositoryProtocol {
    func fetchCurrent() async throws -> FearIndex {
        try await fetchCurrent(forceRefresh: false)
    }

    func fetchHistory(days: Int) async throws -> [FearIndex] {
        try await fetchHistory(days: days, forceRefresh: false)
    }
}
