//
//  FearIndexDataSource.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

protocol FearIndexDataSourceProtocol: Sendable {
    func fetch(forceRefresh: Bool) async throws -> CNNFearGreedResponse
}

extension FearIndexDataSourceProtocol {
    func fetch() async throws -> CNNFearGreedResponse {
        try await fetch(forceRefresh: false)
    }
}

final class FearIndexDataSource: FearIndexDataSourceProtocol, @unchecked Sendable {
    private let networkClient: NetworkClientProtocol
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let cacheKey = "fear_index_current"

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func fetch(forceRefresh: Bool) async throws -> CNNFearGreedResponse {
        // 강제 새로고침이 아니고 캐시가 유효하면 캐시 반환
        if !forceRefresh {
            if let cached = await loadFromCache() {
                Logger.info("Returning cached Fear Index data")
                return cached
            }
        }

        // 네트워크 요청
        guard let url = APIEndpoint.cnnFearIndex.url else {
            throw NetworkError.invalidURL
        }

        let response: CNNFearGreedResponse = try await networkClient.request(
            url: url,
            method: .get,
            headers: APIEndpoint.cnnFearIndex.headers
        )

        // 캐시에 저장 (5분 만료)
        await saveToCache(response)

        return response
    }

    @MainActor
    private func loadFromCache() -> CNNFearGreedResponse? {
        guard let cachedData = CacheManager.shared.loadData(forKey: cacheKey) else {
            return nil
        }
        return try? decoder.decode(CNNFearGreedResponse.self, from: cachedData)
    }

    @MainActor
    private func saveToCache(_ response: CNNFearGreedResponse) {
        guard let data = try? encoder.encode(response) else { return }
        CacheManager.shared.saveData(
            data,
            forKey: cacheKey,
            expiresIn: CacheDuration.fearIndex
        )
    }
}
