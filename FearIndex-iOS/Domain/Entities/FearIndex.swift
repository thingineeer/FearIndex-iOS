//
//  FearIndex.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

struct FearIndex: Sendable, Equatable {
    let score: Double
    let rating: Rating
    let timestamp: Date
    let previousClose: Double
    let previous1Week: Double
    let previous1Month: Double
    let previous1Year: Double

    enum Rating: String, Sendable {
        case extremeFear = "extreme fear"
        case fear = "fear"
        case neutral = "neutral"
        case greed = "greed"
        case extremeGreed = "extreme greed"

        var displayText: String {
            switch self {
            case .extremeFear: return "극단적 공포"
            case .fear: return "공포"
            case .neutral: return "중립"
            case .greed: return "탐욕"
            case .extremeGreed: return "극단적 탐욕"
            }
        }
    }
}
