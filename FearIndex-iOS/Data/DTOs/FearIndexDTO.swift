//
//  FearIndexDTO.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

@preconcurrency import Foundation

// MARK: - CNN API Response

struct CNNFearGreedResponse: Decodable, Sendable {
    let fearAndGreed: FearAndGreedDTO
    let fearAndGreedHistorical: FearAndGreedHistoricalDTO

    enum CodingKeys: String, CodingKey {
        case fearAndGreed = "fear_and_greed"
        case fearAndGreedHistorical = "fear_and_greed_historical"
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fearAndGreed = try container.decode(FearAndGreedDTO.self, forKey: .fearAndGreed)
        fearAndGreedHistorical = try container.decode(FearAndGreedHistoricalDTO.self, forKey: .fearAndGreedHistorical)
    }
}

// MARK: - Current Fear & Greed

struct FearAndGreedDTO: Decodable, Sendable {
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

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        score = try container.decode(Double.self, forKey: .score)
        rating = try container.decode(String.self, forKey: .rating)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        previousClose = try container.decode(Double.self, forKey: .previousClose)
        previous1Week = try container.decode(Double.self, forKey: .previous1Week)
        previous1Month = try container.decode(Double.self, forKey: .previous1Month)
        previous1Year = try container.decode(Double.self, forKey: .previous1Year)
    }
}

// MARK: - Historical Data

struct FearAndGreedHistoricalDTO: Decodable, Sendable {
    let timestamp: Double
    let score: Double
    let rating: String
    let data: [HistoricalDataPoint]

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Double.self, forKey: .timestamp)
        score = try container.decode(Double.self, forKey: .score)
        rating = try container.decode(String.self, forKey: .rating)
        data = try container.decode([HistoricalDataPoint].self, forKey: .data)
    }

    enum CodingKeys: String, CodingKey {
        case timestamp, score, rating, data
    }
}

struct HistoricalDataPoint: Decodable, Sendable {
    let x: Double  // timestamp in milliseconds
    let y: Double  // score
    let rating: String

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        x = try container.decode(Double.self, forKey: .x)
        y = try container.decode(Double.self, forKey: .y)
        rating = try container.decode(String.self, forKey: .rating)
    }

    enum CodingKeys: String, CodingKey {
        case x, y, rating
    }
}

// MARK: - Domain Mapping

extension FearAndGreedDTO {
    nonisolated func toDomain() -> FearIndex? {
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

    nonisolated private func parseTimestamp() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: timestamp)
    }
}

extension HistoricalDataPoint {
    nonisolated func toDomain() -> FearIndex {
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
