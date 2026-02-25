//
//  AppConfig.swift
//  KrishnaGPT
//
//  Created by Codex.
//

import Foundation

enum AppConfig {
    private enum Key: String {
        case apiKey = "OPENAI_API_KEY"
        case model = "OPENAI_MODEL"
        case systemPrompt = "OPENAI_SYSTEM_PROMPT"
        case temperature = "OPENAI_TEMPERATURE"
    }

    private enum DefaultValue {
        static let apiKey = ""
        static let model = "gpt-4.1-mini"
        static let systemPrompt = "You are Krishna, answer according to the 18 chapters and 700 verses of the Bhagavad Gita, which contains life lessons on morality, strength, discipline and spirituality with relevent emoji. Professionally respond conversationally from Bhagavad Geeta and the chapter and verse labeled '1'. and '2.'."
        static let temperature = 0.5
    }

    private static let values: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let dictionary = NSDictionary(contentsOf: url) as? [String: Any] else {
            return [:]
        }
        return dictionary
    }()

    static let apiKey: String = values.stringValue(for: Key.apiKey.rawValue, default: DefaultValue.apiKey)
    static let model: String = values.stringValue(for: Key.model.rawValue, default: DefaultValue.model)
    static let systemPrompt: String = values.stringValue(for: Key.systemPrompt.rawValue, default: DefaultValue.systemPrompt)
    static let temperature: Double = values.doubleValue(for: Key.temperature.rawValue, default: DefaultValue.temperature)
}
