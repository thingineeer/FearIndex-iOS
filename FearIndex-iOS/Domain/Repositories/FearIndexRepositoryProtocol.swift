//
//  FearIndexRepositoryProtocol.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

protocol FearIndexRepositoryProtocol: Sendable {
    func fetchCurrent() async throws -> FearIndex
    func fetchHistory(days: Int) async throws -> [FearIndex]
}
