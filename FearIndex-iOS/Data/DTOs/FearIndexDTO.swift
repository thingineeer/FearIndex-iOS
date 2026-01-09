//
//  FearIndexDTO.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

// MARK: - CNN API Response

struct CNNFearGreedResponse: Codable, Sendable {
    let fearAndGreed: FearAndGreedDTO
    let fearAndGreedHistorical: FearAndGreedHistoricalDTO

    enum CodingKeys: String, CodingKey {
        case fearAndGreed = "fear_and_greed"
        case fearAndGreedHistorical = "fear_and_greed_historical"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fearAndGreed = try container.decode(FearAndGreedDTO.self, forKey: .fearAndGreed)
        fearAndGreedHistorical = try container.decode(FearAndGreedHistoricalDTO.self, forKey: .fearAndGreedHistorical)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fearAndGreed, forKey: .fearAndGreed)
        try container.encode(fearAndGreedHistorical, forKey: .fearAndGreedHistorical)
    }
}

// MARK: - Current Fear & Greed

struct FearAndGreedDTO: Codable, Sendable {
    let score: Double
    let rating: String
    let timestamp: String
    let previousClose: Double
    let previous1Week: Double
    let previous1Month: Double
    let previous1Year: Double

    enum CodingKeys: String, CodingKey {
        case score, rating, timestamp
        case previousClose = "previous_close"
        case previous1Week = "previous_1_week"
        case previous1Month = "previous_1_month"
        case previous1Year = "previous_1_year"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = try container.decode(Double.self, forKey: .score)
        rating = try container.decode(String.self, forKey: .rating)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        previousClose = try container.decode(Double.self, forKey: .previousClose)
        previous1Week = try container.decode(Double.self, forKey: .previous1Week)
        previous1Month = try container.decode(Double.self, forKey: .previous1Month)
        previous1Year = try container.decode(Double.self, forKey: .previous1Year)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(score, forKey: .score)
        try container.encode(rating, forKey: .rating)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(previousClose, forKey: .previousClose)
        try container.encode(previous1Week, forKey: .previous1Week)
        try container.encode(previous1Month, forKey: .previous1Month)
        try container.encode(previous1Year, forKey: .previous1Year)
    }
}

// MARK: - Historical Data

struct FearAndGreedHistoricalDTO: Codable, Sendable {
    let timestamp: Double
    let score: Double
    let rating: String
    let data: [HistoricalDataPoint]

    enum CodingKeys: String, CodingKey {
        case timestamp, score, rating, data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Double.self, forKey: .timestamp)
        score = try container.decode(Double.self, forKey: .score)
        rating = try container.decode(String.self, forKey: .rating)
        data = try container.decode([HistoricalDataPoint].self, forKey: .data)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(score, forKey: .score)
        try container.encode(rating, forKey: .rating)
        try container.encode(data, forKey: .data)
    }
}

struct HistoricalDataPoint: Codable, Sendable {
    let x: Double  // timestamp in milliseconds
    let y: Double  // score
    let rating: String

    enum CodingKeys: String, CodingKey {
        case x, y, rating
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        x = try container.decode(Double.self, forKey: .x)
        y = try container.decode(Double.self, forKey: .y)
        rating = try container.decode(String.self, forKey: .rating)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(rating, forKey: .rating)
    }
}

// MARK: - Domain Mapping

extension FearAndGreedDTO {
    func toDomain() -> FearIndex? {
        guard let date = parseTimestamp() else { return nil }
        let domainRating = FearIndex.Rating(rawValue: rating) ?? .neutral

        return FearIndex(
            score: score,
            rating: domainRating,
            timestamp: date,
            previousClose: previousClose,
            previous1Week: previous1Week,
            previous1Month: previous1Month,
            previous1Year: previous1Year
        )
    }

    private func parseTimestamp() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: timestamp)
    }
}

extension HistoricalDataPoint {
    func toDomain() -> FearIndex {
        let date = Date(timeIntervalSince1970: x / 1000)
        let domainRating = FearIndex.Rating(rawValue: rating) ?? .neutral

        return FearIndex(
            score: y,
            rating: domainRating,
            timestamp: date,
            previousClose: y,
            previous1Week: y,
            previous1Month: y,
            previous1Year: y
        )
    }
}
