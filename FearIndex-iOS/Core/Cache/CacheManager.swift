//
//  CacheManager.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation

// MARK: - Cache Entry (Global - not actor-isolated)

struct CacheEntry: Codable, Sendable {
    let data: Data
    let expirationDate: Date

    var isExpired: Bool {
        Date() >= expirationDate
    }
}

// MARK: - Cache Manager Protocol

@MainActor
protocol CacheManagerProtocol: Sendable {
    func saveData(_ data: Data, forKey key: String, expiresIn seconds: TimeInterval)
    func loadData(forKey key: String) -> Data?
    func isValid(forKey key: String) -> Bool
    func clear(forKey key: String)
    func clearAll()
}

// MARK: - Cache Manager

@MainActor
final class CacheManager: CacheManagerProtocol, Sendable {

    static let shared = CacheManager()

    // MARK: - Memory Cache (NSCache)

    private let memoryCache: NSCache<NSString, NSData> = {
        let cache = NSCache<NSString, NSData>()
        cache.countLimit = 50
        cache.totalCostLimit = 10 * 1024 * 1024  // 10MB
        return cache
    }()

    private var expirationDates: [String: Date] = [:]

    // MARK: - Disk Cache

    private let diskCache: DiskCache

    // MARK: - Init

    init() {
        self.diskCache = DiskCache()
    }

    // MARK: - Save

    func saveData(
        _ data: Data,
        forKey key: String,
        expiresIn seconds: TimeInterval
    ) {
        let expirationDate = Date().addingTimeInterval(seconds)

        // 메모리 캐시에 저장
        memoryCache.setObject(
            data as NSData,
            forKey: key as NSString,
            cost: data.count
        )
        expirationDates[key] = expirationDate

        // 디스크 캐시에 저장
        diskCache.save(data: data, key: key, expirationDate: expirationDate)

        Logger.info("Cache saved: \(key) (expires in \(Int(seconds))s, size: \(data.count) bytes)")
    }

    // MARK: - Load

    func loadData(forKey key: String) -> Data? {
        // 1. 메모리 캐시 확인
        if let data = loadFromMemory(forKey: key) {
            Logger.info("Cache hit (memory): \(key)")
            return data
        }

        // 2. 디스크 캐시 확인
        if let data = diskCache.load(forKey: key) {
            // 메모리 캐시에 복원
            memoryCache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
            Logger.info("Cache hit (disk): \(key)")
            return data
        }

        Logger.info("Cache miss: \(key)")
        return nil
    }

    private func loadFromMemory(forKey key: String) -> Data? {
        guard let expirationDate = expirationDates[key],
              Date() < expirationDate else {
            memoryCache.removeObject(forKey: key as NSString)
            expirationDates.removeValue(forKey: key)
            return nil
        }

        return memoryCache.object(forKey: key as NSString) as Data?
    }

    // MARK: - Validation

    func isValid(forKey key: String) -> Bool {
        // 메모리 캐시 확인
        if let expirationDate = expirationDates[key], Date() < expirationDate {
            return true
        }

        // 디스크 캐시 확인
        return diskCache.isValid(forKey: key)
    }

    // MARK: - Clear

    func clear(forKey key: String) {
        // 메모리 캐시 삭제
        memoryCache.removeObject(forKey: key as NSString)
        expirationDates.removeValue(forKey: key)

        // 디스크 캐시 삭제
        diskCache.clear(forKey: key)

        Logger.info("Cache cleared: \(key)")
    }

    func clearAll() {
        // 메모리 캐시 전체 삭제
        memoryCache.removeAllObjects()
        expirationDates.removeAll()

        // 디스크 캐시 전체 삭제
        diskCache.clearAll()

        Logger.info("All cache cleared")
    }

    // MARK: - Cache Stats

    func cacheStats() -> (memoryCount: Int, diskSize: Int) {
        let memoryCount = expirationDates.count
        let diskSize = diskCache.totalSize()
        return (memoryCount, diskSize)
    }
}

// MARK: - Disk Cache (Sendable, non-actor)

final class DiskCache: Sendable {

    private let cacheDirectoryURL: URL
    private let fileManager = FileManager.default

    init() {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        self.cacheDirectoryURL = urls[0].appendingPathComponent("FearIndexCache", isDirectory: true)
        createDirectoryIfNeeded()
    }

    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectoryURL.path) {
            try? fileManager.createDirectory(
                at: cacheDirectoryURL,
                withIntermediateDirectories: true
            )
        }
    }

    func save(data: Data, key: String, expirationDate: Date) {
        let entry = CacheEntry(data: data, expirationDate: expirationDate)
        guard let encoded = try? JSONEncoder().encode(entry) else { return }

        let fileURL = cacheDirectoryURL.appendingPathComponent(key.toSafeFileName())
        try? encoded.write(to: fileURL, options: .atomic)
    }

    func load(forKey key: String) -> Data? {
        let fileURL = cacheDirectoryURL.appendingPathComponent(key.toSafeFileName())

        guard let encoded = try? Data(contentsOf: fileURL),
              let entry = try? JSONDecoder().decode(CacheEntry.self, from: encoded) else {
            return nil
        }

        guard !entry.isExpired else {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }

        return entry.data
    }

    func isValid(forKey key: String) -> Bool {
        let fileURL = cacheDirectoryURL.appendingPathComponent(key.toSafeFileName())

        guard let encoded = try? Data(contentsOf: fileURL),
              let entry = try? JSONDecoder().decode(CacheEntry.self, from: encoded) else {
            return false
        }

        return !entry.isExpired
    }

    func clear(forKey key: String) {
        let fileURL = cacheDirectoryURL.appendingPathComponent(key.toSafeFileName())
        try? fileManager.removeItem(at: fileURL)
    }

    func clearAll() {
        try? fileManager.removeItem(at: cacheDirectoryURL)
        createDirectoryIfNeeded()
    }

    func totalSize() -> Int {
        var size = 0
        if let enumerator = fileManager.enumerator(
            at: cacheDirectoryURL,
            includingPropertiesForKeys: [.fileSizeKey]
        ) {
            while let fileURL = enumerator.nextObject() as? URL {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += fileSize
                }
            }
        }
        return size
    }
}

// MARK: - String Extension

private extension String {
    func toSafeFileName() -> String {
        let invalidChars = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return components(separatedBy: invalidChars).joined(separator: "_")
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
    static let fearIndex: TimeInterval = 5 * 60        // 5분 (현재 지수)
    static let history: TimeInterval = 15 * 60         // 15분 (단기 히스토리)
    static let longHistory: TimeInterval = 60 * 60     // 1시간 (장기 히스토리)
}
