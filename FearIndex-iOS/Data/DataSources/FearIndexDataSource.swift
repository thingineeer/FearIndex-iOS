//
//  FearIndexDataSource.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

protocol FearIndexDataSourceProtocol: Sendable {
    func fetch() async throws -> CNNFearGreedResponse
}

final class FearIndexDataSource: FearIndexDataSourceProtocol, @unchecked Sendable {
    private let networkClient: NetworkClientProtocol

    nonisolated init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    nonisolated func fetch() async throws -> CNNFearGreedResponse {
        guard let url = APIEndpoint.fearIndexCurrent.url else {
            throw NetworkError.invalidURL
        }

        return try await networkClient.request(
            url: url,
            method: .get,
            headers: APIEndpoint.fearIndexCurrent.headers
        )
    }
}
