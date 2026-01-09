//
//  APIEndpoint.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

enum APIEndpoint: Sendable {
    // CNN Fear & Greed (주식시장, 최근 1년)
    case cnnFearIndex
    case cnnFearIndexHistory(startDate: String)

    // Alternative.me Crypto Fear & Greed (암호화폐, 2018년부터)
    case cryptoFearIndex(limit: Int)  // limit=0 for all data

    nonisolated var url: URL? {
        switch self {
        case .cnnFearIndex:
            let startDate = dateString(daysAgo: 365)
            return URL(string: "\(cnnBaseURL)/index/fearandgreed/graphdata/\(startDate)")
        case .cnnFearIndexHistory(let startDate):
            return URL(string: "\(cnnBaseURL)/index/fearandgreed/graphdata/\(startDate)")
        case .cryptoFearIndex(let limit):
            return URL(string: "\(cryptoBaseURL)/fng/?limit=\(limit)&format=json")
        }
    }

    nonisolated private var cnnBaseURL: String {
        "https://production.dataviz.cnn.io"
    }

    nonisolated private var cryptoBaseURL: String {
        "https://api.alternative.me"
    }

    nonisolated var headers: [String: String] {
        switch self {
        case .cnnFearIndex, .cnnFearIndexHistory:
            return [
                "User-Agent": randomUserAgent,
                "Accept": "*/*",
                "Accept-Language": "en-US,en;q=0.9",
                "Referer": "https://www.cnn.com/markets/fear-and-greed",
                "Origin": "https://www.cnn.com"
            ]
        case .cryptoFearIndex:
            return [
                "Accept": "application/json"
            ]
        }
    }

    nonisolated private var randomUserAgent: String {
        let userAgents = [
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15",
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        ]
        return userAgents.randomElement() ?? userAgents[0]
    }

    nonisolated private func dateString(daysAgo: Int) -> String {
        let date = Calendar.current.date(
            byAdding: .day,
            value: -daysAgo,
            to: Date()
        ) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
