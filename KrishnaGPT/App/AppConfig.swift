//
//  AppConfig.swift
//  KrishnaGPT
//
//  Created by Codex.
//

import Foundation

enum AppConfig {
    private enum Keys {
        static let apiKey = "OPENAI_API_KEY"
        static let model = "OPENAI_MODEL"
        static let systemPrompt = "OPENAI_SYSTEM_PROMPT"
        static let temperature = "OPENAI_TEMPERATURE"
    }

    private static let values: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let rawValue = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dictionary = rawValue as? [String: Any] else {
            return [:]
        }
        return dictionary
    }()

    static let apiKey: String = string(for: Keys.apiKey)
    static let model: String = string(for: Keys.model, default: "gpt-4.1-mini")
    static let systemPrompt: String = string(
        for: Keys.systemPrompt,
        default: "You are Krishna, answer according to the 18 chapters and 700 verses of the Bhagavad Gita, which contains life lessons on morality, strength, discipline and spirituality with relevent emoji. Professionally respond conversationally from Bhagavad Geeta and the chapter and verse labeled '1'. and '2.'."
    )
    static let temperature: Double = double(for: Keys.temperature, default: 0.5)

    private static func string(for key: String, default defaultValue: String = "") -> String {
        guard let value = values[key] else { return defaultValue }
        if let stringValue = value as? String {
            return stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let numberValue = value as? NSNumber {
            return numberValue.stringValue
        }
        return defaultValue
    }

    private static func double(for key: String, default defaultValue: Double) -> Double {
        guard let value = values[key] else { return defaultValue }
        if let doubleValue = value as? Double {
            return doubleValue
        }
        if let numberValue = value as? NSNumber {
            return numberValue.doubleValue
        }
        if let stringValue = value as? String,
           let doubleValue = Double(stringValue) {
            return doubleValue
        }
        return defaultValue
    }
}
