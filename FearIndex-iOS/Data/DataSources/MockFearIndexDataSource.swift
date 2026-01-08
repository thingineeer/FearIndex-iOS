//
//  MockFearIndexDataSource.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

final class MockFearIndexDataSource: FearIndexDataSourceProtocol, @unchecked Sendable {

    nonisolated func fetch() async throws -> CNNFearGreedResponse {
        Logger.info("Using Mock Data")

        let json = """
        {
            "fear_and_greed": {
                "score": 46.6285714285714,
                "rating": "neutral",
                "timestamp": "\(ISO8601DateFormatter().string(from: Date()))",
                "previous_close": 52.1142857142857,
                "previous_1_week": 44.0,
                "previous_1_month": 38.1428571428571,
                "previous_1_year": 34.3142857142857
            },
            "fear_and_greed_historical": {
                "timestamp": \(Date().timeIntervalSince1970 * 1000),
                "score": 46.6285714285714,
                "rating": "neutral",
                "data": \(generateMockHistoryJSON())
            }
        }
        """

        return try! JSONDecoder().decode(
            CNNFearGreedResponse.self,
            from: json.data(using: .utf8)!
        )
    }

    nonisolated private func generateMockHistoryJSON() -> String {
        let calendar = Calendar.current
        let today = Date()

        let mockScores: [(daysAgo: Int, score: Double)] = [
            (0, 46), (1, 52), (2, 48), (3, 45), (4, 42),
            (5, 38), (6, 35), (7, 44), (14, 38), (21, 42),
            (30, 38), (45, 28), (60, 22), (75, 18), (90, 12),
            (100, 8), (110, 15), (120, 25), (150, 35), (180, 45)
        ]

        let dataPoints = mockScores.compactMap { item -> String? in
            guard let date = calendar.date(
                byAdding: .day,
                value: -item.daysAgo,
                to: today
            ) else { return nil }

            let timestamp = date.timeIntervalSince1970 * 1000
            let rating = ratingForScore(item.score)
            return "{\"x\": \(timestamp), \"y\": \(item.score), \"rating\": \"\(rating)\"}"
        }

        return "[\(dataPoints.joined(separator: ", "))]"
    }

    nonisolated private func ratingForScore(_ score: Double) -> String {
        switch score {
        case 0..<25: return "extreme fear"
        case 25..<45: return "fear"
        case 45..<55: return "neutral"
        case 55..<75: return "greed"
        default: return "extreme greed"
        }
    }
}
