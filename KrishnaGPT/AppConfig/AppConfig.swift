//
//  AppConfig.swift
//  KrishnaGPT
//
//  Created by Codex.
//

import Foundation

enum AppEnvironment: String, CaseIterable {
    case dev
    case staging
    case prod

    static let selectionKey = "APP_ENVIRONMENT"

    static func parse(_ rawValue: String?) -> AppEnvironment? {
        guard let normalizedValue = rawValue?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
              !normalizedValue.isEmpty else {
            return nil
        }

        return AppEnvironment(rawValue: normalizedValue)
    }
}

enum AppConfig {
    private enum Key: String {
        case apiKey = "OPENAI_API_KEY"
        case model = "OPENAI_MODEL"
        case temperature = "OPENAI_TEMPERATURE"
    }

    private enum DefaultValue {
        static let apiKey = ""
        static let model = "gpt-5.4-mini"
        static let systemPrompt = """
            You are Lord Krishna, the divine teacher from the Bhagavad Gita. \
            Respond with wisdom, warmth, and clarity as Krishna would when guiding Arjuna. \
            Rules: \
            1) Ground every answer in the Bhagavad Gita's 18 chapters and 700 verses. \
            2) Cite the relevant verse using the format: Bhagavad Gita [Chapter].[Verse] (e.g., Bhagavad Gita 2.47). \
            3) After the citation, provide a clear, practical explanation of how the teaching applies to the user's question. \
            4) If the question falls outside the Gita's scope, gently redirect the conversation back to its teachings. \
            5) Keep responses concise — aim for 1-2 short paragraphs unless the user asks for more detail. \
            6) Do not use emoji.
            """
        static let temperature = 0.5
    }

    // Environment precedence:
    // 1) Runtime variable (Scheme/CI): APP_ENVIRONMENT
    // 2) Info.plist key generated from build settings: APP_ENVIRONMENT
    // 3) Compile-time fallback: Debug -> dev, Release -> prod
    static let environment: AppEnvironment = resolveEnvironment()

    // API key precedence:
    // 1) Runtime env var OPENAI_API_KEY (set in Scheme or CI)
    // 2) Info.plist value (injected from Secrets.xcconfig via INFOPLIST_KEY_OPENAI_API_KEY)
    // 3) Empty string default
    static let apiKey: String = {
        let runtimeValue = ProcessInfo.processInfo.environment[Key.apiKey.rawValue]
        let runtimeKey = runtimeValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !runtimeKey.isEmpty {
            return runtimeKey
        }

        return infoPlistString(for: Key.apiKey.rawValue) ?? DefaultValue.apiKey
    }()

    static let model: String = infoPlistString(for: Key.model.rawValue) ?? DefaultValue.model
    static let systemPrompt: String = DefaultValue.systemPrompt
    static let temperature: Double = infoPlistDouble(for: Key.temperature.rawValue) ?? DefaultValue.temperature

    // MARK: - Private

    private static func resolveEnvironment() -> AppEnvironment {
        if let runtimeEnvironment = AppEnvironment.parse(ProcessInfo.processInfo.environment[AppEnvironment.selectionKey]) {
            return runtimeEnvironment
        }

        if let infoPlistEnvironment = AppEnvironment.parse(Bundle.main.object(forInfoDictionaryKey: AppEnvironment.selectionKey) as? String) {
            return infoPlistEnvironment
        }

#if DEBUG
        return .dev
#else
        return .prod
#endif
    }

    /// Reads a string value from the generated Info.plist.
    /// Returns nil if the key is missing or the trimmed value is empty.
    private static func infoPlistString(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Reads a Double value from the generated Info.plist.
    /// Info.plist values injected from xcconfig are always strings, so this parses the string.
    private static func infoPlistDouble(for key: String) -> Double? {
        guard let stringValue = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }
        return Double(stringValue.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
