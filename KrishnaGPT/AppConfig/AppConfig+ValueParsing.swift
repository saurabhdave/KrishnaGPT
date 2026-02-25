//
//  AppConfig+ValueParsing.swift
//  KrishnaGPT
//
//  Created by Codex.
//

import Foundation

extension Dictionary where Key == String, Value == Any {
    func stringValue(for key: String, default defaultValue: String) -> String {
        guard let value = self[key] else { return defaultValue }

        if let stringValue = value as? String {
            let trimmedValue = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedValue.isEmpty ? defaultValue : trimmedValue
        }

        if let numberValue = value as? NSNumber {
            return numberValue.stringValue
        }

        return defaultValue
    }

    func doubleValue(for key: String, default defaultValue: Double) -> Double {
        guard let value = self[key] else { return defaultValue }

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
