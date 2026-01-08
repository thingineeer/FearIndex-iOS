//
//  Logger.swift
//  FearIndex-iOS
//
//  Created by 이명진 on 1/9/25.
//

import Foundation
import OSLog

enum LogLevel: String, Sendable {
    case debug = "🔍 DEBUG"
    case info = "ℹ️ INFO"
    case warning = "⚠️ WARNING"
    case error = "❌ ERROR"
    case network = "🌐 NETWORK"
}

struct Logger: Sendable {

    nonisolated static func debug(
        _ message: String,
        file: String = #file,
        line: Int = #line
    ) {
        log(.debug, message, file: file, line: line)
    }

    nonisolated static func info(
        _ message: String,
        file: String = #file,
        line: Int = #line
    ) {
        log(.info, message, file: file, line: line)
    }

    nonisolated static func warning(
        _ message: String,
        file: String = #file,
        line: Int = #line
    ) {
        log(.warning, message, file: file, line: line)
    }

    nonisolated static func error(
        _ message: String,
        file: String = #file,
        line: Int = #line
    ) {
        log(.error, message, file: file, line: line)
    }

    nonisolated static func network(
        _ message: String,
        file: String = #file,
        line: Int = #line
    ) {
        log(.network, message, file: file, line: line)
    }

    nonisolated private static func log(
        _ level: LogLevel,
        _ message: String,
        file: String,
        line: Int
    ) {
        #if DEBUG
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = formattedTimestamp()
        let output = """

        ╔══════════════════════════════════════════════════════════
        ║ \(level.rawValue)
        ╠══════════════════════════════════════════════════════════
        ║ 📍 \(fileName):\(line)
        ║ 🕐 \(timestamp)
        ╠══════════════════════════════════════════════════════════
        ║ \(message)
        ╚══════════════════════════════════════════════════════════
        """
        print(output)
        #endif
    }

    nonisolated static func networkRequest(
        url: URL,
        method: String,
        headers: [String: String]?
    ) {
        #if DEBUG
        var headersString = "None"
        if let headers = headers {
            headersString = headers
                .map { "  \($0.key): \($0.value)" }
                .joined(separator: "\n")
        }

        let output = """

        ╔══════════════════════════════════════════════════════════
        ║ 🌐 NETWORK REQUEST
        ╠══════════════════════════════════════════════════════════
        ║ 📤 \(method) \(url.absoluteString)
        ╠══════════════════════════════════════════════════════════
        ║ Headers:
        \(headersString)
        ╚══════════════════════════════════════════════════════════
        """
        print(output)
        #endif
    }

    nonisolated static func networkResponse(
        url: URL,
        statusCode: Int,
        data: Data?,
        error: Error?
    ) {
        #if DEBUG
        let dataPreview = prettyPrintJSON(data) ?? "No data"

        var output = """

        ╔══════════════════════════════════════════════════════════
        ║ 🌐 NETWORK RESPONSE
        ╠══════════════════════════════════════════════════════════
        ║ 📥 \(url.absoluteString)
        ║ 📊 Status: \(statusCode)
        """

        if let error = error {
            output += "\n║ ❌ Error: \(error.localizedDescription)"
        }

        output += """

        ╠══════════════════════════════════════════════════════════
        ║ Response:
        \(dataPreview)
        ╚══════════════════════════════════════════════════════════
        """
        print(output)
        #endif
    }

    nonisolated private static func formattedTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }

    nonisolated private static func prettyPrintJSON(_ data: Data?) -> String? {
        guard let data = data else { return nil }

        if let json = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(
            withJSONObject: json,
            options: .prettyPrinted
           ),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
                .split(separator: "\n")
                .map { "║ \($0)" }
                .joined(separator: "\n")
        }

        return String(data: data, encoding: .utf8)
    }
}
