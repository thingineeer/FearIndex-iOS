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

        // 365일치 일별 데이터 생성
        var dataPoints: [String] = []

        for daysAgo in 0...365 {
            guard let date = calendar.date(
                byAdding: .day,
                value: -daysAgo,
                to: today
            ) else { continue }

            // 사인 곡선 기반 + 노이즈로 자연스러운 변동 생성
            let baseValue = 50.0
            let amplitude = 30.0
            let frequency = Double(daysAgo) / 30.0  // 30일 주기
            let noise = Double.random(in: -5...5)
            let score = max(0, min(100, baseValue + amplitude * sin(frequency) + noise))

            let timestamp = date.timeIntervalSince1970 * 1000
            let rating = ratingForScore(score)
            dataPoints.append("{\"x\": \(timestamp), \"y\": \(score), \"rating\": \"\(rating)\"}")
        }

        // 시간순 정렬 (과거 -> 현재)
        return "[\(dataPoints.reversed().joined(separator: ", "))]"
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
