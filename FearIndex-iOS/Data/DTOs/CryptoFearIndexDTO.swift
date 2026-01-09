//
//  CryptoFearIndexDTO.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

// MARK: - Alternative.me Crypto Fear & Greed API Response

struct CryptoFearGreedResponse: Codable, Sendable {
    let name: String
    let data: [CryptoFearDataPoint]
    let metadata: CryptoMetadata

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        data = try container.decode([CryptoFearDataPoint].self, forKey: .data)
        metadata = try container.decode(CryptoMetadata.self, forKey: .metadata)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(data, forKey: .data)
        try container.encode(metadata, forKey: .metadata)
    }

    enum CodingKeys: String, CodingKey {
        case name, data, metadata
    }
}

struct CryptoFearDataPoint: Codable, Sendable {
    let value: String
    let valueClassification: String
    let timestamp: String
    let timeUntilUpdate: String?

    enum CodingKeys: String, CodingKey {
        case value
        case valueClassification = "value_classification"
        case timestamp
        case timeUntilUpdate = "time_until_update"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try container.decode(String.self, forKey: .value)
        valueClassification = try container.decode(String.self, forKey: .valueClassification)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        timeUntilUpdate = try container.decodeIfPresent(String.self, forKey: .timeUntilUpdate)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: .value)
        try container.encode(valueClassification, forKey: .valueClassification)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(timeUntilUpdate, forKey: .timeUntilUpdate)
    }
}

struct CryptoMetadata: Codable, Sendable {
    let error: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        error = try container.decodeIfPresent(String.self, forKey: .error)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(error, forKey: .error)
    }

    enum CodingKeys: String, CodingKey {
        case error
    }
}

// MARK: - Domain Mapping

extension CryptoFearDataPoint {
    func toDomain() -> FearIndex {
        let score = Double(value) ?? 50.0
        let date = Date(timeIntervalSince1970: Double(timestamp) ?? 0)
        let domainRating = mapRating(valueClassification)

        return FearIndex(
            score: score,
            rating: domainRating,
            timestamp: date,
            previousClose: score,
            previous1Week: score,
            previous1Month: score,
            previous1Year: score
        )
    }

    private func mapRating(_ classification: String) -> FearIndex.Rating {
        switch classification.lowercased() {
        case "extreme fear":
            return .extremeFear
        case "fear":
            return .fear
        case "neutral":
            return .neutral
        case "greed":
            return .greed
        case "extreme greed":
            return .extremeGreed
        default:
            return .neutral
        }
    }
}
