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
        case systemPrompt = "OPENAI_SYSTEM_PROMPT"
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
            5) Keep responses concise — aim for 2-4 short paragraphs unless the user asks for more detail. \
            6) Do not use emoji.
            """
        static let temperature = 0.5
    }

    // Environment precedence:
    // 1) Runtime variable (Scheme/CI): APP_ENVIRONMENT
    // 2) Info.plist key generated from build settings: APP_ENVIRONMENT
    // 3) Compile-time fallback: Debug -> dev, Release -> prod
    static let environment: AppEnvironment = resolveEnvironment()

    private static let values: [String: Any] = {
        let candidateFileNames = [
            "Config.\(environment.rawValue)",
            "Config"
        ]

        for fileName in candidateFileNames {
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "plist"),
                  let dictionary = NSDictionary(contentsOf: url) as? [String: Any] else {
                continue
            }
            return dictionary
        }

        return [:]
    }()

    static let apiKey: String = {
        // Keep API keys out of source control and bundled config when possible.
        // Preferred source is a runtime env var in the Run scheme or CI.
        let runtimeValue = ProcessInfo.processInfo.environment[Key.apiKey.rawValue]
        let runtimeKey = runtimeValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !runtimeKey.isEmpty {
            return runtimeKey
        }

        return values.stringValue(for: Key.apiKey.rawValue, default: DefaultValue.apiKey)
    }()
    static let model: String = values.stringValue(for: Key.model.rawValue, default: DefaultValue.model)
    static let systemPrompt: String = values.stringValue(for: Key.systemPrompt.rawValue, default: DefaultValue.systemPrompt)
    static let temperature: Double = values.doubleValue(for: Key.temperature.rawValue, default: DefaultValue.temperature)

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
}
