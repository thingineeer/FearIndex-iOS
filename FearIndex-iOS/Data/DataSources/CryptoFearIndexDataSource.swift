//
//  CryptoFearIndexDataSource.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

protocol CryptoFearIndexDataSourceProtocol: Sendable {
    func fetch(limit: Int, forceRefresh: Bool) async throws -> CryptoFearGreedResponse
}

extension CryptoFearIndexDataSourceProtocol {
    func fetchAll(forceRefresh: Bool) async throws -> CryptoFearGreedResponse {
        try await fetch(limit: 0, forceRefresh: forceRefresh)
    }
}

final class CryptoFearIndexDataSource: CryptoFearIndexDataSourceProtocol, @unchecked Sendable {
    private let networkClient: NetworkClientProtocol
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let cacheKey = "crypto_fear_index"

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func fetch(limit: Int, forceRefresh: Bool) async throws -> CryptoFearGreedResponse {
        let cacheKeyWithLimit = "\(cacheKey)_\(limit)"

        // 강제 새로고침이 아니고 캐시가 유효하면 캐시 반환
        if !forceRefresh {
            if let cached = await loadFromCache(key: cacheKeyWithLimit) {
                Logger.info("Returning cached Crypto Fear Index data")
                return cached
            }
        }

        // 네트워크 요청
        guard let url = APIEndpoint.cryptoFearIndex(limit: limit).url else {
            throw NetworkError.invalidURL
        }

        let response: CryptoFearGreedResponse = try await networkClient.request(
            url: url,
            method: .get,
            headers: APIEndpoint.cryptoFearIndex(limit: limit).headers
        )

        // 캐시에 저장 (장기 데이터는 1시간 만료)
        await saveToCache(response, key: cacheKeyWithLimit)

        return response
    }

    @MainActor
    private func loadFromCache(key: String) -> CryptoFearGreedResponse? {
        guard let cachedData = CacheManager.shared.loadData(forKey: key) else {
            return nil
        }
        return try? decoder.decode(CryptoFearGreedResponse.self, from: cachedData)
    }

    @MainActor
    private func saveToCache(_ response: CryptoFearGreedResponse, key: String) {
        guard let data = try? encoder.encode(response) else { return }
        CacheManager.shared.saveData(
            data,
            forKey: key,
            expiresIn: CacheDuration.longHistory
        )
    }
}
