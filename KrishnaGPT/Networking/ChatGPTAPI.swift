//
//  ChatGPTAPI.swift
//  KrishnaGPT
//
//  Created by Saurabh Dave on 2/7/23.
//

import Foundation
import SDOpenAIClient

protocol ChatNetworking {
    func sendMessageStream(text: String, language: LanguageType) async throws -> AsyncThrowingStream<String, Error>
    func sendMessage(_ text: String, language: LanguageType) async throws -> String
    func clearHistory() async
}

final class ChatGPTAPI: ChatNetworking {
    private let openAIClient: OpenAIClient

    init(
        apiKey: String,
        model: String = "gpt-5.4-mini",
        systemPrompt: String = "You are Krishna, answer according to the 18 chapters and 700 verses of the Bhagavad Gita, which contains life lessons on morality, strength, discipline and spirituality with relevent emoji. Professionally respond conversationally from Bhagavad Geeta and the chapter and verse labeled '1'. and '2.'.",
        temperature: Double = 0.5,
        urlSession: URLSession = .shared
    ) throws {
        let configuration = try OpenAIClientConfiguration(
            apiKey: APIKey(apiKey),
            model: OpenAIModel(rawValue: model),
            systemPrompt: systemPrompt,
            temperature: temperature,
            historyTrimmingStrategy: .both(maxCharacters: 16_000, maxItems: 100),
            requestTimeout: 60,
            retryPolicy: .standard
        )

        self.openAIClient = OpenAIClient(
            configuration: configuration,
            session: urlSession
        )
    }

    private func languageInstruction(for language: LanguageType) -> String {
        "Answer in \(language.rawValue) and do not answer as the user."
    }
}

extension ChatGPTAPI {
    func sendMessageStream(text: String, language: LanguageType) async throws -> AsyncThrowingStream<String, Error> {
        try await openAIClient.stream(text, additionalInstructions: languageInstruction(for: language))
    }

    func sendMessage(_ text: String, language: LanguageType) async throws -> String {
        try await openAIClient.send(text, additionalInstructions: languageInstruction(for: language))
    }

    func clearHistory() async {
        await openAIClient.clearHistory()
    }
}
