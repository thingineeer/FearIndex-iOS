//
//  NetworkClient.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

protocol NetworkClientProtocol: Sendable {
    func request<T: Decodable>(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?
    ) async throws -> T
}

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
}

enum NetworkError: Error, Sendable {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError(Error)
    case unknown(Error)
}

final class NetworkClient: NetworkClientProtocol, @unchecked Sendable {
    private let session: URLSession
    private let decoder: JSONDecoder

    nonisolated init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    nonisolated func request<T: Decodable>(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        applyHeaders(&request, headers: headers)

        Logger.networkRequest(url: url, method: method.rawValue, headers: headers)

        do {
            let (data, response) = try await performRequest(request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            Logger.networkResponse(url: url, statusCode: statusCode, data: data, error: nil)

            try validateResponse(response)
            return try decode(data)
        } catch {
            Logger.error("Network error: \(error.localizedDescription)")
            throw error
        }
    }

    nonisolated private func applyHeaders(
        _ request: inout URLRequest,
        headers: [String: String]?
    ) {
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
    }

    nonisolated private func performRequest(
        _ request: URLRequest
    ) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw NetworkError.unknown(error)
        }
    }

    nonisolated private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    nonisolated private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            Logger.error("Decoding error: \(error)")
            throw NetworkError.decodingError(error)
        }
    }
}
