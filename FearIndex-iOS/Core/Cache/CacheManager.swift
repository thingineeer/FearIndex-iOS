//
//  CacheManager.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

@MainActor
protocol CacheManagerProtocol: Sendable {
    func saveData(_ data: Data, forKey key: String, expiresIn seconds: TimeInterval)
    func loadData(forKey key: String) -> Data?
    func isValid(forKey key: String) -> Bool
    func clear(forKey key: String)
    func clearAll()
}

@MainActor
final class CacheManager: CacheManagerProtocol, Sendable {

    static let shared = CacheManager()

    private let defaults: UserDefaults

    private enum Keys {
        static let expirationPrefix = "cache_expiration_"
        static let dataPrefix = "cache_data_"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Save

    func saveData(
        _ data: Data,
        forKey key: String,
        expiresIn seconds: TimeInterval
    ) {
        let expirationDate = Date().addingTimeInterval(seconds)
        defaults.set(data, forKey: Keys.dataPrefix + key)
        defaults.set(expirationDate, forKey: Keys.expirationPrefix + key)
        Logger.info("Cache saved for key: \(key), expires in \(Int(seconds))s")
    }

    // MARK: - Load

    func loadData(forKey key: String) -> Data? {
        guard isValid(forKey: key) else {
            Logger.info("Cache miss or expired for key: \(key)")
            return nil
        }

        guard let data = defaults.data(forKey: Keys.dataPrefix + key) else {
            return nil
        }

        Logger.info("Cache hit for key: \(key)")
        return data
    }

    // MARK: - Validation

    func isValid(forKey key: String) -> Bool {
        guard let expirationDate = defaults.object(
            forKey: Keys.expirationPrefix + key
        ) as? Date else {
            return false
        }

        return Date() < expirationDate
    }

    // MARK: - Clear

    func clear(forKey key: String) {
        defaults.removeObject(forKey: Keys.dataPrefix + key)
        defaults.removeObject(forKey: Keys.expirationPrefix + key)
        Logger.info("Cache cleared for key: \(key)")
    }

    func clearAll() {
        let keys = defaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix(Keys.dataPrefix) || key.hasPrefix(Keys.expirationPrefix) {
                defaults.removeObject(forKey: key)
            }
        }
        Logger.info("All cache cleared")
    }
}

// MARK: - Cache Keys

enum CacheKey: Sendable {
    static let fearIndexCurrent = "fear_index_current"
    static let fearIndexHistory = "fear_index_history"

    static func historyKey(days: Int) -> String {
        "fear_index_history_\(days)d"
    }
}

// MARK: - Cache Duration

enum CacheDuration: Sendable {
    static let fearIndex: TimeInterval = 5 * 60        // 5분
    static let history: TimeInterval = 15 * 60         // 15분
    static let longHistory: TimeInterval = 60 * 60     // 1시간 (연간 데이터)
}
